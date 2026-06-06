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
const Level = require('../models/Level');
const Subject = require('../models/Subject');

// @desc    Get admin reports overview
// @route   GET /api/analytics/admin-reports
// @access  Private (Admin)
exports.getAdminReports = async (req, res) => {
    try {
        const [
            studentCount,
            teacherCount,
            adminCount,
            lessonCount,
            quizCount,
            sectionCount,
            levelCount,
            subjectCount,
            pendingTeachers,
        ] = await Promise.all([
            User.countDocuments({ role: 'student' }),
            User.countDocuments({ role: 'teacher' }),
            User.countDocuments({ role: 'admin' }),
            Lesson.countDocuments(),
            Quiz.countDocuments(),
            Section.countDocuments(),
            Level.countDocuments(),
            Subject.countDocuments(),
            User.countDocuments({ role: 'teacher', isApproved: false }),
        ]);

        // 1. Academic Performance (Average Quiz Score & Passing Rate)
        const attempts = await QuizAttempt.find();
        let totalScore = 0;
        let totalQuestions = 0;
        let passedCount = 0;

        attempts.forEach(attempt => {
            totalScore += attempt.score;
            const qCount = attempt.totalQuestions || 1;
            totalQuestions += qCount;
            if (attempt.score / qCount >= 0.75) {
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

        const latestLogs = await Log.find().sort({ timestamp: -1 }).limit(8);

        res.json({
            overview: {
                studentCount,
                teacherCount,
                adminCount,
                lessonCount,
                quizCount,
                sectionCount,
                levelCount,
                subjectCount,
                pendingTeachers,
            },
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
            topSections,
            recentActivity: latestLogs.map(log => ({
                user: log.user,
                role: log.role,
                action: log.action,
                icon: log.icon,
                timestamp: log.timestamp,
            })),
        });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get teacher reports overview
// @route   GET /api/analytics/teacher-reports
// @access  Private (Teacher)
exports.getTeacherReports = async (req, res) => {
    try {
        const teacherId = req.user._id;

        // Find all sections handled by this teacher
        const teacher = await User.findById(teacherId).populate('handledClasses.section');
        const sections = teacher.handledClasses.map(hc => hc.section ? hc.section._id : null).filter(s => s != null);

        // Get all students in these sections
        const students = await User.find({ role: 'student', section: { $in: sections } });
        const studentIds = students.map(s => s._id);

        const studentCount = students.length;

        // Get all quiz attempts for these students
        const attempts = await QuizAttempt.find({ student: { $in: studentIds } });
        
        let totalScore = 0;
        let totalQuestions = 0;
        let passedCount = 0;

        attempts.forEach(attempt => {
            totalScore += attempt.score;
            const qCount = attempt.totalQuestions || 1;
            totalQuestions += qCount;
            if (attempt.score / qCount >= 0.75) {
                passedCount++;
            }
        });

        const averageScore = totalQuestions > 0 ? Math.round((totalScore / totalQuestions) * 100) : 0;
        const passingRate = attempts.length > 0 ? Math.round((passedCount / attempts.length) * 100) : 0;
        
        // Mock average study time
        const avgStudyTime = "1.2h";

        // Top 3 Students
        const topStudents = await User.find({ _id: { $in: studentIds } })
            .select('name xp')
            .sort({ xp: -1 })
            .limit(3);

        res.json({
            overview: {
                studentCount,
                averageScore,
                passingRate,
                avgStudyTime
            },
            topStudents
        });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Per-section performance for the teacher's handled sections
// @route   GET /api/analytics/teacher/section-performance
// @access  Private (Teacher)
exports.getTeacherSectionPerformance = async (req, res) => {
    try {
        const teacherId = req.user._id;

        const teacher = await User.findById(teacherId).populate('handledClasses.section');
        const sectionIds = (teacher?.handledClasses || [])
            .map(hc => (hc.section ? hc.section._id : null))
            .filter(Boolean);

        if (sectionIds.length === 0) {
            return res.json([]);
        }

        const sections = await Section.find({ _id: { $in: sectionIds } }).lean();
        const students = await User.find({ role: 'student', section: { $in: sectionIds } })
            .select('_id section')
            .lean();

        const studentToSection = new Map(students.map(s => [s._id.toString(), s.section?.toString()]));
        const studentIds = students.map(s => s._id);

        const attempts = await QuizAttempt.find({ student: { $in: studentIds } })
            .select('student quiz score totalQuestions')
            .lean();

        const stats = {};
        sections.forEach(sec => {
            stats[sec._id.toString()] = {
                sectionId: sec._id,
                name: sec.name,
                attempts: 0,
                totalScore: 0,
                totalQuestions: 0,
                passed: 0,
                quizSet: new Set(),
            };
        });

        attempts.forEach(att => {
            const secId = studentToSection.get(att.student.toString());
            if (!secId || !stats[secId]) return;
            const bucket = stats[secId];
            const qCount = att.totalQuestions || 1;
            bucket.attempts += 1;
            bucket.totalScore += att.score;
            bucket.totalQuestions += qCount;
            if (att.score / qCount >= 0.75) bucket.passed += 1;
            if (att.quiz) bucket.quizSet.add(att.quiz.toString());
        });

        const result = Object.values(stats).map(s => ({
            sectionId: s.sectionId,
            name: s.name,
            attempts: s.attempts,
            averageScore: s.totalQuestions > 0
                ? Math.round((s.totalScore / s.totalQuestions) * 100)
                : 0,
            passRate: s.attempts > 0 ? Math.round((s.passed / s.attempts) * 100) : 0,
            quizCount: s.quizSet.size,
        })).sort((a, b) => b.averageScore - a.averageScore);

        res.json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Aggregated weak topics across the teacher's students
// @route   GET /api/analytics/teacher/weak-topics
// @access  Private (Teacher)
exports.getTeacherWeakTopics = async (req, res) => {
    try {
        const teacherId = req.user._id;

        const teacher = await User.findById(teacherId).populate('handledClasses.section');
        const sectionIds = (teacher?.handledClasses || [])
            .map(hc => (hc.section ? hc.section._id : null))
            .filter(Boolean);

        if (sectionIds.length === 0) {
            return res.json([]);
        }

        const students = await User.find({ role: 'student', section: { $in: sectionIds } }).select('_id name').lean();
        const studentIds = students.map(s => s._id);
        const studentLookup = new Map(students.map(s => [s._id.toString(), s.name]));

        const attempts = await QuizAttempt.find({ student: { $in: studentIds } }).populate({
            path: 'quiz',
            populate: { path: 'lesson', select: 'title subject' },
        }).lean();

        const map = {};
        attempts.forEach(att => {
            const lesson = att.quiz?.lesson;
            if (!lesson) return;
            const key = lesson._id.toString();
            if (!map[key]) {
                map[key] = {
                    topicId: lesson._id,
                    topic: lesson.title,
                    totalScore: 0,
                    totalQuestions: 0,
                    attempts: 0,
                    students: {},
                };
            }
            map[key].totalScore += att.score;
            map[key].totalQuestions += att.totalQuestions || 1;
            map[key].attempts += 1;

            // Track per-student performance within this topic
            const sid = att.student.toString();
            if (!map[key].students[sid]) {
                map[key].students[sid] = {
                    studentId: att.student,
                    name: studentLookup.get(sid) || 'Student',
                    score: 0,
                    questions: 0,
                    attempts: 0,
                };
            }
            map[key].students[sid].score += att.score;
            map[key].students[sid].questions += att.totalQuestions || 1;
            map[key].students[sid].attempts += 1;
        });

        const weak = Object.values(map)
            .map(t => {
                // Students who scored below 75% in this topic are the ones struggling
                const strugglingStudents = Object.values(t.students)
                    .map(s => ({
                        studentId: s.studentId,
                        name: s.name,
                        averageScore: s.questions > 0
                            ? Math.round((s.score / s.questions) * 100)
                            : 0,
                        attempts: s.attempts,
                    }))
                    .filter(s => s.averageScore < 75)
                    .sort((a, b) => a.averageScore - b.averageScore);

                return {
                    topicId: t.topicId,
                    topic: t.topic,
                    attempts: t.attempts,
                    averageScore: t.totalQuestions > 0
                        ? Math.round((t.totalScore / t.totalQuestions) * 100)
                        : 0,
                    strugglingStudents,
                    strugglingCount: strugglingStudents.length,
                };
            })
            .filter(t => t.averageScore < 75)
            .sort((a, b) => a.averageScore - b.averageScore);

        res.json(weak);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Monitoring snapshot for the teacher (recent activity, inactive students, completion rates)
// @route   GET /api/analytics/teacher/monitoring
// @access  Private (Teacher)
exports.getTeacherMonitoring = async (req, res) => {
    try {
        const teacherId = req.user._id;

        const teacher = await User.findById(teacherId).populate('handledClasses.section');
        const sectionIds = (teacher?.handledClasses || [])
            .map(hc => (hc.section ? hc.section._id : null))
            .filter(Boolean);

        if (sectionIds.length === 0) {
            return res.json({
                recentActivity: [],
                inactiveStudents: [],
                completion: { totalStudents: 0, activeStudents: 0, inactiveCount: 0, completionRate: 0 },
            });
        }

        const students = await User.find({ role: 'student', section: { $in: sectionIds } })
            .select('_id name section')
            .populate('section', 'name')
            .lean();

        const studentIds = students.map(s => s._id);
        const studentLookup = new Map(students.map(s => [s._id.toString(), s]));

        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const recentAttempts = await QuizAttempt.find({
            student: { $in: studentIds },
            date: { $gte: sevenDaysAgo },
        })
            .populate('quiz', 'title')
            .sort({ date: -1 })
            .limit(15)
            .lean();

        const recentActivity = recentAttempts.map(att => {
            const stu = studentLookup.get(att.student.toString());
            return {
                studentId: att.student,
                studentName: stu?.name || 'Unknown',
                section: stu?.section?.name || null,
                quizTitle: att.quiz?.title || 'Quiz',
                score: att.score,
                totalQuestions: att.totalQuestions,
                date: att.date,
            };
        });

        const lastAttemptByStudent = await QuizAttempt.aggregate([
            { $match: { student: { $in: studentIds } } },
            { $group: { _id: '$student', lastDate: { $max: '$date' }, attempts: { $sum: 1 } } },
        ]);

        const lastByStudent = new Map(
            lastAttemptByStudent.map(a => [a._id.toString(), { lastDate: a.lastDate, attempts: a.attempts }])
        );

        const inactiveStudents = students
            .map(s => {
                const info = lastByStudent.get(s._id.toString());
                return {
                    studentId: s._id,
                    studentName: s.name,
                    section: s.section?.name || null,
                    lastActive: info?.lastDate || null,
                    totalAttempts: info?.attempts || 0,
                };
            })
            .filter(s => !s.lastActive || s.lastActive < sevenDaysAgo)
            .sort((a, b) => {
                if (!a.lastActive) return -1;
                if (!b.lastActive) return 1;
                return new Date(a.lastActive) - new Date(b.lastActive);
            })
            .slice(0, 25);

        const activeStudents = students.length - inactiveStudents.filter(s => !s.lastActive || s.lastActive < sevenDaysAgo).length;
        const completionRate = students.length > 0
            ? Math.round((activeStudents / students.length) * 100)
            : 0;

        res.json({
            recentActivity,
            inactiveStudents,
            completion: {
                totalStudents: students.length,
                activeStudents,
                inactiveCount: inactiveStudents.length,
                completionRate,
            },
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Learning statistics + activity history + achievements for the logged-in student
// @route   GET /api/analytics/student/stats
// @access  Private (Student)
exports.getStudentStats = async (req, res) => {
    try {
        const studentId = req.user._id;

        const attempts = await QuizAttempt.find({ student: studentId })
            .populate({
                path: 'quiz',
                select: 'title lesson',
                populate: { path: 'lesson', select: 'title' },
            })
            .sort({ date: -1 })
            .lean();

        const user = await User.findById(studentId).select('xp name createdAt').lean();

        // Learning statistics
        const totalQuizzes = attempts.length;
        let totalScore = 0;
        let totalQuestions = 0;
        let passed = 0;
        let bestScorePct = 0;
        let totalTime = 0;

        attempts.forEach(a => {
            totalScore += a.score;
            const q = a.totalQuestions || 1;
            totalQuestions += q;
            const pct = Math.round((a.score / q) * 100);
            if (pct >= 75) passed += 1;
            if (pct > bestScorePct) bestScorePct = pct;
            totalTime += a.timeTaken || 0;
        });

        const averageScore = totalQuestions > 0 ? Math.round((totalScore / totalQuestions) * 100) : 0;
        const passRate = totalQuizzes > 0 ? Math.round((passed / totalQuizzes) * 100) : 0;

        // Activity history (latest 20)
        const activityHistory = attempts.slice(0, 20).map(a => ({
            quizTitle: a.quiz?.title || 'Quiz',
            lessonTitle: a.quiz?.lesson?.title || null,
            score: a.score,
            totalQuestions: a.totalQuestions,
            percentage: a.totalQuestions ? Math.round((a.score / a.totalQuestions) * 100) : 0,
            xpEarned: a.xpEarned || 0,
            date: a.date,
        }));

        // Achievements (derived from milestones)
        const xp = user?.xp || 0;
        const achievements = [
            {
                key: 'first_quiz',
                title: 'First Steps',
                description: 'Complete your first quiz',
                icon: 'star',
                unlocked: totalQuizzes >= 1,
            },
            {
                key: 'five_quizzes',
                title: 'Getting Started',
                description: 'Complete 5 quizzes',
                icon: 'flame',
                unlocked: totalQuizzes >= 5,
            },
            {
                key: 'perfect_score',
                title: 'Perfectionist',
                description: 'Score 100% on a quiz',
                icon: 'checkmark_seal',
                unlocked: bestScorePct >= 100,
            },
            {
                key: 'high_achiever',
                title: 'High Achiever',
                description: 'Reach 500 XP',
                icon: 'rosette',
                unlocked: xp >= 500,
            },
            {
                key: 'scholar',
                title: 'Scholar',
                description: 'Reach 1000 XP',
                icon: 'graduationcap',
                unlocked: xp >= 1000,
            },
            {
                key: 'consistent',
                title: 'Consistent Learner',
                description: 'Maintain a 75% pass rate',
                icon: 'chart_bar',
                unlocked: totalQuizzes >= 3 && passRate >= 75,
            },
        ];

        res.json({
            statistics: {
                totalQuizzes,
                averageScore,
                passRate,
                bestScore: bestScorePct,
                totalXp: xp,
                totalTimeSeconds: totalTime,
            },
            activityHistory,
            achievements,
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
