const User = require('../models/User');
const QuizAttempt = require('../models/QuizAttempt');
const Quiz = require('../models/Quiz');
const Lesson = require('../models/Lesson');

// @desc    Identify weak topics for a student
// @route   GET /api/analytics/weak-topics
// @access  Private (Student)
exports.getWeakTopics = async (req, res) => {
    try {
        // 1. Get all quiz attempts for this student
        const attempts = await QuizAttempt.find({ student: req.user._id })
            .populate({
                path: 'quiz',
                populate: { path: 'lesson', populate: { path: 'subject' } }
            });

        if (!attempts.length) {
            return res.json({ weakTopics: [], message: "No quiz data yet" });
        }

        // 2. Aggregate scores by lesson/subject
        const performanceMap = {};

        attempts.forEach(attempt => {
            const lesson = attempt.quiz.lesson;
            const lessonId = lesson._id.toString();
            
            if (!performanceMap[lessonId]) {
                performanceMap[lessonId] = {
                    title: lesson.title,
                    totalScore: 0,
                    totalQuestions: 0,
                    count: 0
                };
            }
            
            performanceMap[lessonId].totalScore += attempt.score;
            performanceMap[lessonId].totalQuestions += attempt.totalQuestions;
            performanceMap[lessonId].count += 1;
        });

        // 3. Calculate percentage and identify weak ones (below 75%)
        const weakTopics = Object.values(performanceMap)
            .map(p => ({
                topic: p.title,
                score: Math.round((p.totalScore / p.totalQuestions) * 100),
                attempts: p.count
            }))
            .filter(p => p.score < 75)
            .sort((a, b) => a.score - b.score);

        res.json(weakTopics);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get leaderboard rankings for a section
// @route   GET /api/analytics/leaderboard/:sectionId
// @access  Private
exports.getLeaderboard = async (req, res) => {
    try {
        const { sectionId } = req.params;

        const rankings = await User.find({ 
            role: 'student', 
            section: sectionId 
        })
        .select('name xp achievements')
        .sort({ xp: -1 })
        .limit(10);

        res.json(rankings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getSectionTrends = async (req, res) => {
    try {
        // Placeholder for future trend analysis
        res.json({ message: "Trend analysis feature coming soon" });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const Log = require('../models/Log');
const Section = require('../models/Section');

// @desc    Get admin reports overview
// @route   GET /api/analytics/admin-reports
// @access  Private (Admin)
exports.getAdminReports = async (req, res) => {
    try {
        // 1. Academic Performance (Average Quiz Score & Passing Rate)
        const attempts = await QuizAttempt.find();
        let totalScore = 0;
        let totalQuestions = 0;
        let passedCount = 0;

        attempts.forEach(attempt => {
            totalScore += attempt.score;
            totalQuestions += attempt.totalQuestions;
            if (attempt.score / attempt.totalQuestions >= 0.75) {
                passedCount++;
            }
        });

        const averageScore = totalQuestions > 0 ? Math.round((totalScore / totalQuestions) * 100) : 0;
        const passingRate = attempts.length > 0 ? Math.round((passedCount / attempts.length) * 100) : 0;

        // 2. User Activity (Logs in the last 7 days)
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const recentLogs = await Log.find({ timestamp: { $gte: sevenDaysAgo } });
        
        // Group logs by day
        const activityByDay = {};
        for(let i=6; i>=0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const dateStr = `${d.getMonth()+1}/${d.getDate()}`;
            activityByDay[dateStr] = 0;
        }

        recentLogs.forEach(log => {
            const d = new Date(log.timestamp);
            const dateStr = `${d.getMonth()+1}/${d.getDate()}`;
            if(activityByDay[dateStr] !== undefined) {
                activityByDay[dateStr]++;
            }
        });

        // 3. Quiz & Assessment (Top Sections)
        // Group attempts by section through student
        const attemptsWithStudent = await QuizAttempt.find().populate('student');
        const sectionScores = {};

        attemptsWithStudent.forEach(attempt => {
            if (!attempt.student || !attempt.student.section) return;
            const secId = attempt.student.section.toString();
            if (!sectionScores[secId]) {
                sectionScores[secId] = { total: 0, count: 0 };
            }
            sectionScores[secId].total += (attempt.score / attempt.totalQuestions);
            sectionScores[secId].count++;
        });

        const sectionIds = Object.keys(sectionScores);
        const sections = await Section.find({ _id: { $in: sectionIds } });

        const topSections = sections.map(sec => {
            const data = sectionScores[sec._id.toString()];
            return {
                name: sec.name,
                average: Math.round((data.total / data.count) * 100)
            };
        }).sort((a, b) => b.average - a.average).slice(0, 5);

        res.json({
            academicPerformance: {
                averageScore,
                passingRate,
                totalAttempts: attempts.length
            },
            userActivity: {
                labels: Object.keys(activityByDay),
                data: Object.values(activityByDay),
                totalActions: recentLogs.length
            },
            topSections
        });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
