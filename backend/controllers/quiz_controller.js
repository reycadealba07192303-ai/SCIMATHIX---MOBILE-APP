const Quiz = require('../models/Quiz');
const Question = require('../models/Question');
const Lesson = require('../models/Lesson');
const QuizAttempt = require('../models/QuizAttempt');
const User = require('../models/User');
const { generateQuiz } = require('../services/ai_service');
const { randomizeQuestion } = require('../utils/randomizer');
const { evaluate } = require('mathjs');

// @desc    Generate a quiz using AI based on a lesson
// @route   POST /api/quizzes/generate
// @access  Private (Teacher)
exports.createAIQuiz = async (req, res) => {
    const { lessonId, title, count } = req.body;

    try {
        const lesson = await Lesson.findById(lessonId);
        if (!lesson) return res.status(404).json({ message: 'Lesson not found' });

        // 1. Call AI Service
        const aiResponse = await generateQuiz(lesson.title, lesson.summary, count);
        const aiQuestions = Array.isArray(aiResponse) ? aiResponse : (aiResponse.questions || []);

        // 2. Create Quiz Meta
        const quiz = await Quiz.create({
            title: title || `${lesson.title} Quiz`,
            lesson: lessonId,
            teacher: req.user._id
        });

        // 3. Create Questions in DB
        const questions = aiQuestions.map(q => ({
            ...q,
            quiz: quiz._id
        }));

        await Question.insertMany(questions);

        res.status(201).json({ quiz, questionCount: questions.length });
    } catch (error) {
        console.error('Quiz Generation Controller Error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get a randomized version of the quiz for a student
// @route   GET /api/quizzes/:id/take
// @access  Private (Student)
exports.getQuizForStudent = async (req, res) => {
    try {
        const quiz = await Quiz.findById(req.params.id);
        if (!quiz) return res.status(404).json({ message: 'Quiz not found' });

        const questions = await Question.find({ quiz: quiz._id });
        
        // Randomize each question for THIS student
        const randomizedQuestions = questions.map(q => randomizeQuestion(q));

        // We don't send the 'actualAnswer' to the frontend to prevent cheating!
        const safeQuestions = randomizedQuestions.map(({ actualAnswer, ...rest }) => rest);

        res.json({
            quizId: quiz._id,
            title: quiz.title,
            questions: safeQuestions
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Submit quiz results
// @route   POST /api/quizzes/:id/submit
// @access  Private (Student)
exports.submitQuiz = async (req, res) => {
    const { answers, timeTaken } = req.body; 

    try {
        const quiz = await Quiz.findById(req.params.id);
        if (!quiz) return res.status(404).json({ message: 'Quiz not found' });

        let score = 0;
        const resultDetails = [];

        for (const ans of answers) {
            const question = await Question.findById(ans.questionId);
            if (!question) continue;

            let isCorrect = false;
            let calculatedCorrectAnswer;

            try {
                let formula = question.correctAnswerTemplate;
                const vars = ans.randomizedValues || {};
                
                for (const [key, val] of Object.entries(vars)) {
                    formula = formula.replace(new RegExp(`{${key}}`, 'g'), val);
                }

                calculatedCorrectAnswer = evaluate(formula);
                if (typeof calculatedCorrectAnswer === 'number') {
                    calculatedCorrectAnswer = Math.round(calculatedCorrectAnswer * 100) / 100;
                }

                isCorrect = ans.chosenAnswer == calculatedCorrectAnswer;
            } catch (e) {
                console.error("Submission verification error:", e);
            }

            if (isCorrect) score++;

            resultDetails.push({
                question: ans.questionId,
                chosenAnswer: ans.chosenAnswer,
                correctAnswer: calculatedCorrectAnswer,
                isCorrect
            });
        }

        const xpEarned = score * 10;

        const quizAttempt = await QuizAttempt.create({
            student: req.user._id,
            quiz: quiz._id,
            score,
            totalQuestions: answers.length,
            answers: resultDetails,
            xpEarned,
            timeTaken: timeTaken || 0
        });

        await User.findByIdAndUpdate(req.user._id, {
            $inc: { xp: xpEarned }
        });
        
        res.json({
            score,
            total: answers.length,
            xpEarned,
            results: resultDetails
        });
    } catch (error) {
        console.error('Quiz Submission Error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get leaderboard data
// @route   GET /api/quizzes/leaderboard
// @access  Private
exports.getLeaderboard = async (req, res) => {
    try {
        const topUsers = await User.find({ role: 'student' })
            .select('name xp level')
            .sort({ xp: -1 })
            .limit(10);
        res.json(topUsers);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all quizzes
// @route   GET /api/quizzes
// @access  Private
exports.getQuizzes = async (req, res) => {
    try {
        let query = {};
        if (req.user.role === 'teacher') {
            query.teacher = req.user._id;
        } else if (req.user.role === 'student') {
            // Only return quizzes for lessons assigned to this student's section
            const studentSection = await require('../models/Section').findOne({ students: req.user._id });
            if (studentSection) {
                const assignedLessons = await Lesson.find({ sections: studentSection._id }).select('_id');
                const lessonIds = assignedLessons.map(l => l._id);
                query.lesson = { $in: lessonIds };
            } else {
                return res.json([]);
            }
        }
        
        const quizzes = await Quiz.find(query).populate('lesson', 'title');
        res.json(quizzes);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
