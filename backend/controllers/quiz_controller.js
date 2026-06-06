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
const normalizeAnswer = (value) => String(value ?? '').trim().toLowerCase();
const answersMatch = (chosen, correct) => {
    const chosenNumber = Number(chosen);
    const correctNumber = Number(correct);
    if (!Number.isNaN(chosenNumber) && !Number.isNaN(correctNumber)) {
        return Math.abs(chosenNumber - correctNumber) < 0.01;
    }
    return normalizeAnswer(chosen) === normalizeAnswer(correct);
};

const ensureTeacherOwnsQuiz = async (quizId, teacherId) => {
    const quiz = await Quiz.findById(quizId);
    if (!quiz) return { error: { status: 404, message: 'Quiz not found' } };
    if (quiz.teacher.toString() !== teacherId.toString()) {
        return { error: { status: 403, message: 'You can only manage your own quizzes.' } };
    }
    return { quiz };
};

// @desc    Generate a quiz using AI based on a lesson
// @route   POST /api/quizzes/generate
// @access  Private (Teacher)
const hasPlaceholderContent = (question) => {
    const text = [
        question.baseQuestion,
        ...(question.optionsTemplate || [])
    ].join(' ').toLowerCase();

    return text.includes('sample grade 9 question') ||
        text.includes('analysis failed') ||
        text.includes('lesson was saved successfully') ||
        text.includes('option a') ||
        text.includes('option b') ||
        text.includes('option c') ||
        text.includes('option d');
};

const normalizeGeneratedQuestion = (question) => {
    if (!question || !question.baseQuestion || !question.correctAnswerTemplate) return null;

    const schemaType = question.type === 'problem-solving' || question.type === 'identification'
        ? question.type
        : 'multiple-choice';
    const options = Array.isArray(question.optionsTemplate)
        ? question.optionsTemplate.map(option => String(option).trim()).filter(Boolean)
        : [];
    let correctAnswer = String(question.correctAnswerTemplate).trim();

    if (schemaType === 'multiple-choice') {
        if (options.length < 2) return null;
        const matchingOption = options.find(option => normalizeAnswer(option) === normalizeAnswer(correctAnswer));
        if (!matchingOption) {
            return null;
        }
        correctAnswer = matchingOption;
    }

    return {
        baseQuestion: String(question.baseQuestion).trim(),
        variables: question.variables || {},
        type: schemaType,
        imageUrl: question.imageUrl || '',
        optionsTemplate: options,
        correctAnswerTemplate: correctAnswer,
        explanationTemplate: question.explanationTemplate || '',
        solutionSteps: Array.isArray(question.solutionSteps) ? question.solutionSteps : [],
    };
};

exports.createAIQuiz = async (req, res) => {
    const { lessonId, lessonIds, title, count, type, types, isPractice = false, scheduledDate, scheduledTime, endTime } = req.body;

    try {
        const selectedLessonIds = Array.isArray(lessonIds) && lessonIds.length > 0
            ? lessonIds
            : (lessonId ? [lessonId] : []);

        if (selectedLessonIds.length === 0) {
            return res.status(400).json({ message: 'Please select at least one lesson.' });
        }

        const lessons = await Lesson.find({ _id: { $in: selectedLessonIds } });
        if (lessons.length === 0) return res.status(404).json({ message: 'Lesson not found' });

        const unauthorizedLesson = lessons.find(lesson => lesson.teacher.toString() !== req.user._id.toString());
        if (unauthorizedLesson) {
            return res.status(403).json({ message: 'You can only create quizzes from your own lessons.' });
        }

        const selectedTypes = Array.isArray(types) && types.length > 0 ? types : [type || 'Multiple Choice'];
        const lesson = lessons[0];
        const lessonSource = [
            ...lessons.map(item => [
                `Lesson Title: ${item.title}`,
                item.summary ? `Summary: ${item.summary}` : '',
                item.content ? `Content: ${item.content}` : '',
            ].filter(Boolean).join('\n'))
        ].filter(Boolean).join('\n\n');

        // 1. Call AI Service
        const requestedCount = Math.max(1, Math.min(Number(count) || 10, 30));
        const aiResponse = await generateQuiz(lessons.map(item => item.title).join(', '), lessonSource, requestedCount, selectedTypes);
        const aiQuestions = Array.isArray(aiResponse) ? aiResponse : (aiResponse?.questions || []);
        const validQuestions = aiQuestions
            .map(normalizeGeneratedQuestion)
            .filter(Boolean)
            .filter(q => !hasPlaceholderContent(q))
            .slice(0, requestedCount);

        if (validQuestions.length === 0) {
            return res.status(502).json({
                message: 'AI could not generate usable questions from the selected lesson. Please try again or check the uploaded lesson text.'
            });
        }

        // 2. Create Quiz Meta
        const quiz = await Quiz.create({
            title: title || `${lesson.title}${lessons.length > 1 ? ' and More' : ''} Quiz`,
            lesson: lesson._id,
            teacher: req.user._id,
            timeLimit: isPractice ? 0 : (req.body.timeLimit || 20),
            passingScore: isPractice ? 0 : (req.body.passingScore || Math.ceil(validQuestions.length * 0.6)),
            isPractice: Boolean(isPractice),
            scheduledDate: scheduledDate || null,
            scheduledTime: scheduledTime || null,
            endTime: endTime || null,
            difficulty: 'easy'
        });

        // 3. Create Questions in DB
        const questions = validQuestions.map(q => ({
            ...q,
            quiz: quiz._id,
            difficulty: 'easy'
        }));

        await Question.insertMany(questions);

        const io = req.app.get('io');
        if (io) {
            lessons.forEach(item => {
                item.sections.forEach(sectionId => {
                    io.emit('classroom_updated', {
                        action: 'quiz_created',
                        sectionId: sectionId.toString(),
                        subjectId: item.subject.toString(),
                        quizId: quiz._id.toString(),
                    });
                });
            });
        }

        res.status(201).json({ quiz, questions });
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

        if (quiz.scheduledDate) {
            const dateStr = new Date(quiz.scheduledDate).toISOString().split('T')[0];
            const now = new Date();
            
            if (quiz.scheduledTime) {
                const startDateTime = new Date(`${dateStr}T${quiz.scheduledTime}:00`);
                if (now < startDateTime) {
                    return res.status(403).json({ message: 'This quiz is not yet available to take.' });
                }
            }
            
            if (quiz.endTime) {
                const endDateTime = new Date(`${dateStr}T${quiz.endTime}:00`);
                if (now > endDateTime) {
                    return res.status(403).json({ message: 'The time to take this quiz has already passed.' });
                }
            }
        }

        const existingAttempt = await QuizAttempt.findOne({ quiz: quiz._id, student: req.user._id });
        if (existingAttempt) {
            return res.status(403).json({ message: 'You have already taken this quiz. Please wait for your teacher to allow a retake.' });
        }

        const questions = (await Question.find({ quiz: quiz._id }))
            .filter(question => !hasPlaceholderContent({
                baseQuestion: question.baseQuestion,
                optionsTemplate: question.optionsTemplate
            }));

        if (questions.length === 0) {
            return res.status(422).json({
                message: 'This quiz contains placeholder questions and needs to be regenerated.'
            });
        }
        
        // Randomize each question for THIS student
        const randomizedQuestions = questions.map(q => randomizeQuestion(q));

        // We don't send the 'actualAnswer' to the frontend to prevent cheating!
        const safeQuestions = randomizedQuestions.map(({ actualAnswer, ...rest }) => rest);

        res.json({
            quizId: quiz._id,
            title: quiz.title,
            timeLimit: quiz.timeLimit,
            isPractice: quiz.isPractice,
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

        if (quiz.scheduledDate && quiz.endTime) {
            const dateStr = new Date(quiz.scheduledDate).toISOString().split('T')[0];
            const endDateTime = new Date(`${dateStr}T${quiz.endTime}:00`);
            // We allow a small grace period of 2 minutes for network delays during auto-submit
            if (new Date() > new Date(endDateTime.getTime() + 2 * 60000)) {
                return res.status(403).json({ message: 'Quiz submission rejected: Past the deadline.' });
            }
        }

        let score = 0;
        const resultDetails = [];

        for (const ans of answers) {
            const question = await Question.findById(ans.questionId);
            if (!question) continue;

            let isCorrect = false;
            let calculatedCorrectAnswer;

            let formula = question.correctAnswerTemplate;

            try {
                const vars = ans.randomizedValues || {};
                
                for (const [key, val] of Object.entries(vars)) {
                    formula = formula.replace(new RegExp(`{${key}}`, 'g'), val);
                }

                calculatedCorrectAnswer = evaluate(formula);
                if (typeof calculatedCorrectAnswer === 'number') {
                    calculatedCorrectAnswer = Math.round(calculatedCorrectAnswer * 100) / 100;
                }
            } catch (e) {
                // Fallback to text answer if evaluate fails
                calculatedCorrectAnswer = formula;
            }
            
            isCorrect = answersMatch(ans.chosenAnswer, calculatedCorrectAnswer);

            if (isCorrect) score++;

            resultDetails.push({
                question: ans.questionId,
                questionText: ans.questionText || question.baseQuestion,
                questionType: question.type,
                imageUrl: question.imageUrl || '',
                chosenAnswer: ans.chosenAnswer,
                correctAnswer: String(calculatedCorrectAnswer),
                isCorrect,
                explanation: question.explanationTemplate || '',
                solutionSteps: question.solutionSteps || [],
                actualValues: ans.randomizedValues || {}
            });
        }

        // Teachers testing their own quiz: return score/results without
        // persisting a QuizAttempt or awarding XP, so analytics and the
        // leaderboard remain free of teacher test data.
        if (req.user.role === 'teacher') {
            return res.json({
                score,
                total: answers.length,
                xpEarned: 0,
                results: resultDetails
            });
        }

        const xpEarned = quiz.isPractice ? 0 : score * 10;

        const quizAttempt = await QuizAttempt.create({
            student: req.user._id,
            quiz: quiz._id,
            score,
            totalQuestions: answers.length,
            answers: resultDetails,
            xpEarned,
            timeTaken: timeTaken || 0
        });

        if (xpEarned > 0) {
            await User.findByIdAndUpdate(req.user._id, {
                $inc: { xp: xpEarned }
            });
        }
        
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
// Query params:
//   ?category=Science|Mathematics  — filter by subject category
//   ?section=<sectionId>           — filter to students in a specific section
//   ?limit=<number>                — max results (default 50)
exports.getLeaderboard = async (req, res) => {
    try {
        const { category, section, limit, period } = req.query;
        const maxResults = Math.min(parseInt(limit) || 50, 100);

        // Optional time-window filter (weekly / monthly) based on attempt date
        let dateFilter = null;
        if (period === 'weekly') {
            const d = new Date();
            d.setDate(d.getDate() - 7);
            dateFilter = d;
        } else if (period === 'monthly') {
            const d = new Date();
            d.setDate(d.getDate() - 30);
            dateFilter = d;
        }

        // If category is specified, aggregate from quiz attempts for that category
        if (category && ['Science', 'Mathematics'].includes(category)) {
            const Subject = require('../models/Subject');
            const Section = require('../models/Section');

            // Find subjects in this category
            const subjects = await Subject.find({ category }).select('_id');
            const subjectIds = subjects.map(s => s._id);

            // Find lessons that belong to those subjects
            const lessons = await Lesson.find({ subject: { $in: subjectIds } }).select('_id');
            const lessonIds = lessons.map(l => l._id);

            // Find non-practice quizzes tied to those lessons (include practice for category ranking)
            const quizzes = await Quiz.find({ lesson: { $in: lessonIds } }).select('_id title');
            const quizIds = quizzes.map(q => q._id);

            if (quizIds.length === 0) {
                return res.json([]);
            }

            // Build student filter
            let studentFilter = {};
            if (section) {
                const sectionIds = section.split(',');
                const sections = await Section.find({ _id: { $in: sectionIds } }).select('students');
                const studentIds = sections.reduce((acc, sec) => acc.concat(sec.students), []);
                studentFilter = { student: { $in: studentIds } };
            }

            const matchStage = { quiz: { $in: quizIds }, ...studentFilter };
            if (dateFilter) matchStage.date = { $gte: dateFilter };

            // Aggregate per student: use score*10 as XP (handles legacy attempts where xpEarned=0)
            const pipeline = [
                { $match: matchStage },
                { $group: {
                    _id: '$student',
                    categoryXp: { $sum: { $cond: [{ $gt: ['$xpEarned', 0] }, '$xpEarned', { $multiply: ['$score', 10] }] } },
                    totalScore: { $sum: '$score' },
                    totalQuestions: { $sum: '$totalQuestions' },
                    quizzesTaken: { $sum: 1 },
                    bestScore: { $max: '$score' },
                    lastQuiz: { $last: '$quiz' }
                }},
                { $sort: { categoryXp: -1 } },
                { $limit: maxResults },
                { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'user' } },
                { $unwind: '$user' },
                { $match: { 'user.role': 'student' } },
                { $lookup: { from: 'sections', localField: 'user.section', foreignField: '_id', as: 'sectionInfo' } },
                { $unwind: { path: '$sectionInfo', preserveNullAndEmptyArrays: true } },
                { $lookup: { from: 'quizzes', localField: 'lastQuiz', foreignField: '_id', as: 'quizInfo' } },
                { $unwind: { path: '$quizInfo', preserveNullAndEmptyArrays: true } },
                { $project: {
                    _id: '$user._id',
                    name: '$user.name',
                    profilePicture: '$user.profilePicture',
                    section: { _id: '$sectionInfo._id', name: '$sectionInfo.name' },
                    xp: '$categoryXp',
                    totalScore: 1,
                    totalQuestions: 1,
                    quizzesTaken: 1,
                    bestScore: 1,
                    lastQuizTitle: '$quizInfo.title'
                }}
            ];

            const leaderboard = await QuizAttempt.aggregate(pipeline);
            return res.json(leaderboard);
        }

        // Default: overall leaderboard.
        // For all-time use User.xp; for weekly/monthly compute XP from attempts in the window.
        if (dateFilter) {
            const Section = require('../models/Section');
            let studentFilter = {};
            if (section) {
                const sectionIds = section.split(',');
                const sections = await Section.find({ _id: { $in: sectionIds } }).select('students');
                const studentIds = sections.reduce((acc, sec) => acc.concat(sec.students), []);
                studentFilter = { student: { $in: studentIds } };
            }
            const pipeline = [
                { $match: { date: { $gte: dateFilter }, ...studentFilter } },
                { $group: {
                    _id: '$student',
                    xp: { $sum: { $cond: [{ $gt: ['$xpEarned', 0] }, '$xpEarned', { $multiply: ['$score', 10] }] } },
                }},
                { $sort: { xp: -1 } },
                { $limit: maxResults },
                { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'user' } },
                { $unwind: '$user' },
                { $match: { 'user.role': 'student' } },
                { $lookup: { from: 'sections', localField: 'user.section', foreignField: '_id', as: 'sectionInfo' } },
                { $unwind: { path: '$sectionInfo', preserveNullAndEmptyArrays: true } },
                { $project: {
                    _id: '$user._id',
                    name: '$user.name',
                    profilePicture: '$user.profilePicture',
                    section: { _id: '$sectionInfo._id', name: '$sectionInfo.name' },
                    xp: 1,
                }}
            ];
            const leaderboard = await QuizAttempt.aggregate(pipeline);
            return res.json(leaderboard);
        }

        let userQuery = { role: 'student' };
        if (section) {
            const sectionIds = section.split(',');
            userQuery.section = { $in: sectionIds };
        }

        const topUsers = await User.find(userQuery)
            .select('name xp profilePicture section')
            .populate('section', 'name')
            .sort({ xp: -1 })
            .limit(maxResults);

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
        let query = { isPractice: { $ne: true } };
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
        
        const quizzes = await Quiz.find(query).populate('lesson', 'title subject sections').lean();
        
        const quizzesWithQuestions = await Promise.all(quizzes.map(async (quiz) => {
            const questions = await require('../models/Question').find({ quiz: quiz._id }).select('_id baseQuestion optionsTemplate');
            return { ...quiz, questions };
        }));

        // For students, filter out quizzes that only have placeholder questions or already taken
        if (req.user.role === 'student') {
            const studentAttempts = await QuizAttempt.find({ student: req.user._id }).select('quiz');
            const attemptedQuizIds = studentAttempts.map(a => a.quiz.toString());

            const validQuizzes = quizzesWithQuestions.filter(quiz => {
                if (attemptedQuizIds.includes(quiz._id.toString())) return false; // Already taken
                if (!quiz.questions || quiz.questions.length === 0) return false;
                const hasUsable = quiz.questions.some(q => !hasPlaceholderContent({
                    baseQuestion: q.baseQuestion,
                    optionsTemplate: q.optionsTemplate
                }));
                return hasUsable;
            });
            // Strip question content before sending to student
            return res.json(validQuizzes.map(q => ({ ...q, questions: q.questions.map(qn => ({ _id: qn._id })) })));
        }

        res.json(quizzesWithQuestions);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get a quiz with questions for teacher preview/edit
// @route   GET /api/quizzes/:id
// @access  Private (Teacher)
exports.getQuizById = async (req, res) => {
    try {
        const quiz = await Quiz.findById(req.params.id)
            .populate({ path: 'lesson', select: 'title subject', populate: { path: 'subject', select: 'name category' } })
            .lean();
        if (!quiz) return res.status(404).json({ message: 'Quiz not found' });

        if (req.user.role === 'teacher' && quiz.teacher.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'You can only view your own quizzes.' });
        }

        const questions = await Question.find({ quiz: quiz._id }).lean();
        res.json({ quiz, questions });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update a quiz and its questions
// @route   PUT /api/quizzes/:id
// @access  Private (Teacher)
exports.updateQuiz = async (req, res) => {
    try {
        const { quiz, error } = await ensureTeacherOwnsQuiz(req.params.id, req.user._id);
        if (error) return res.status(error.status).json({ message: error.message });

        const { title, timeLimit, passingScore, isActive, isPractice, questions, scheduledDate, scheduledTime, endTime } = req.body;
        if (title !== undefined) quiz.title = title;
        if (timeLimit !== undefined) quiz.timeLimit = Number(timeLimit);
        if (passingScore !== undefined) quiz.passingScore = Number(passingScore);
        if (isActive !== undefined) quiz.isActive = Boolean(isActive);
        if (isPractice !== undefined) quiz.isPractice = Boolean(isPractice);
        if (scheduledDate !== undefined) quiz.scheduledDate = scheduledDate;
        if (scheduledTime !== undefined) quiz.scheduledTime = scheduledTime;
        if (endTime !== undefined) quiz.endTime = endTime;
        quiz.difficulty = 'easy';
        await quiz.save();

        if (Array.isArray(questions)) {
            await Question.deleteMany({ quiz: quiz._id });
            await Question.insertMany(questions.map(q => ({
                quiz: quiz._id,
                type: q.type || 'multiple-choice',
                baseQuestion: q.baseQuestion || q.text || 'Question',
                imageUrl: q.imageUrl || '',
                variables: q.variables || {},
                correctAnswerTemplate: q.correctAnswerTemplate || q.correctAnswer || '',
                optionsTemplate: q.optionsTemplate || q.options || [],
                explanationTemplate: q.explanationTemplate || q.explanation || '',
                solutionSteps: q.solutionSteps || [],
                difficulty: 'easy',
            })));
        }

        const updatedQuestions = await Question.find({ quiz: quiz._id });

        const lesson = await Lesson.findById(quiz.lesson);
        const io = req.app.get('io');
        if (io && lesson) {
            lesson.sections.forEach(sectionId => {
                io.emit('classroom_updated', {
                    action: 'quiz_updated',
                    sectionId: sectionId.toString(),
                    subjectId: lesson.subject.toString(),
                    quizId: quiz._id.toString(),
                });
            });
        }

        res.json({ quiz, questions: updatedQuestions });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Delete a quiz
// @route   DELETE /api/quizzes/:id
// @access  Private (Teacher)
exports.deleteQuiz = async (req, res) => {
    try {
        const { quiz, error } = await ensureTeacherOwnsQuiz(req.params.id, req.user._id);
        if (error) return res.status(error.status).json({ message: error.message });
        
        // Delete all associated questions
        await Question.deleteMany({ quiz: quiz._id });
        // Deduct XP from students before deleting attempts
        const attemptsToDelete = await QuizAttempt.find({ quiz: quiz._id });
        for (const attempt of attemptsToDelete) {
            if (attempt.xpEarned > 0) {
                await require('../models/User').findByIdAndUpdate(attempt.student, {
                    $inc: { xp: -attempt.xpEarned }
                });
            }
        }
        
        // Cascade delete student attempts so no orphaned QuizAttempt records remain.
        await QuizAttempt.deleteMany({ quiz: quiz._id });
        const lesson = await Lesson.findById(quiz.lesson);
        await quiz.deleteOne();

        const io = req.app.get('io');
        if (io && lesson) {
            lesson.sections.forEach(sectionId => {
                io.emit('classroom_updated', {
                    action: 'quiz_deleted',
                    sectionId: sectionId.toString(),
                    subjectId: lesson.subject.toString(),
                    quizId: quiz._id.toString(),
                });
            });
        }
        
        res.json({ message: 'Quiz deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get quiz by lesson ID
// @route   GET /api/quizzes/lesson/:lessonId
// @access  Private
exports.getQuizByLesson = async (req, res) => {
    try {
        const lesson = await Lesson.findById(req.params.lessonId);
        if (!lesson) {
            return res.status(404).json({ message: 'Lesson not found' });
        }

        let quiz = null;
        const practiceQuizzes = await Quiz.find({ lesson: lesson._id, isPractice: true }).sort({ createdAt: -1 });

        for (const practiceQuiz of practiceQuizzes) {
            const usableQuestionCount = (await Question.find({ quiz: practiceQuiz._id }))
                .filter(question => !hasPlaceholderContent({
                    baseQuestion: question.baseQuestion,
                    optionsTemplate: question.optionsTemplate
                })).length;

            if (usableQuestionCount > 0) {
                quiz = practiceQuiz;
                break;
            }
        }

        if (!quiz && lesson.content) {
            const generatedQuestions = await generateQuiz(lesson.title, lesson.content, 5, ['Multiple Choice']);
            const validQuestions = generatedQuestions
                .map(normalizeGeneratedQuestion)
                .filter(Boolean)
                .filter(q => !hasPlaceholderContent(q));

            if (validQuestions.length > 0) {
                quiz = await Quiz.create({
                    title: `${lesson.title} - Practice Quiz`,
                    lesson: lesson._id,
                    teacher: lesson.teacher,
                    timeLimit: 0,
                    passingScore: 60,
                    isPractice: true,
                    difficulty: 'easy'
                });

                await Question.insertMany(validQuestions.map(q => ({
                    ...q,
                    quiz: quiz._id,
                    difficulty: 'easy'
                })));
            }
        }

        if (!quiz) {
            return res.status(404).json({ message: 'Quiz not found for this lesson' });
        }
        res.json(quiz);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get submissions and leaderboard for a quiz
// @route   GET /api/quizzes/:id/submissions
// @access  Private (Teacher)
exports.getQuizSubmissions = async (req, res) => {
    try {
        const quiz = await Quiz.findById(req.params.id);
        if (!quiz) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        if (quiz.teacher.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'You can only view submissions for your own quizzes.' });
        }

        const submissions = await QuizAttempt.find({ quiz: req.params.id })
            .populate('student', 'name studentId')
            .sort({ score: -1, timeTaken: 1 })
            .lean();

        res.json({ quiz, submissions });
    } catch (error) {
        console.error('Get Quiz Submissions Error:', error);
        res.status(500).json({ message: 'Failed to fetch quiz submissions' });
    }
};
