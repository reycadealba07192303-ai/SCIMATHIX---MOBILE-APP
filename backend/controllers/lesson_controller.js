const Lesson = require('../models/Lesson');
const Section = require('../models/Section');
const fs = require('fs');
const pdf = require('pdf-parse');
const { analyzeLesson, generateQuiz } = require('../services/ai_service');
const Quiz = require('../models/Quiz');
const Question = require('../models/Question');

const normalizeAnswer = (value) => String(value ?? '').trim().toLowerCase();
const isUsableGeneratedQuestion = (question) => {
    if (!question?.baseQuestion || !question?.correctAnswerTemplate) return false;
    if (question.type === 'multiple-choice') {
        const options = Array.isArray(question.optionsTemplate) ? question.optionsTemplate : [];
        return options.length >= 2 &&
            options.some(option => normalizeAnswer(option) === normalizeAnswer(question.correctAnswerTemplate));
    }
    return true;
};

// @desc    Create a new lesson with AI analysis
// @route   POST /api/lessons
// @access  Private (Teacher/Admin)
exports.createLesson = async (req, res) => {
    const { title, subject, content: manualContent, sections } = req.body;
    let extractedContent = manualContent || "";

    console.log('=== CREATE LESSON DEBUG ===');
    console.log('Title:', title);
    console.log('Subject:', subject);
    console.log('Sections (raw):', sections);
    console.log('File present:', !!req.file);
    if (req.file) {
        console.log('File details:', { filename: req.file.filename, mimetype: req.file.mimetype, path: req.file.path, size: req.file.size });
    }

    try {
        // 1. Handle File Upload & Text Extraction
        let fileUrl = "";
        if (req.file) {
            fileUrl = `/uploads/${req.file.filename}`;
            console.log('File uploaded to:', fileUrl);
            
            // If it's a PDF, extract text
            if (req.file.mimetype === 'application/pdf') {
                console.log('Extracting text from PDF...');
                const dataBuffer = fs.readFileSync(req.file.path);
                const data = await pdf(dataBuffer);
                extractedContent = data.text;
                console.log('Extracted text length:', extractedContent.length);
            }
        }

        if (!extractedContent) {
            return res.status(400).json({ message: "No content provided (manually or via file)" });
        }

        // 2. Perform AI Analysis (Summary & Objectives)
        const aiAnalysis = await analyzeLesson(extractedContent);

        const lesson = await Lesson.create({
            title,
            subject,
            content: extractedContent,
            summary: aiAnalysis.summary,
            objectives: aiAnalysis.learningObjectives,
            fileUrl,
            teacher: req.user._id,
            sections: sections ? JSON.parse(sections) : []
        });

        // 4. Automatically generate an inside-lesson practice quiz.
        try {
            const aiQuestions = (await generateQuiz(title, extractedContent, 5, ['Multiple Choice']))
                .filter(isUsableGeneratedQuestion);
            if (aiQuestions && aiQuestions.length > 0) {
                const newQuiz = await Quiz.create({
                    title: `${title} - Practice Quiz`,
                    lesson: lesson._id,
                    teacher: req.user._id,
                    timeLimit: 0,
                    passingScore: 60,
                    isPractice: true
                });

                const questionDocs = aiQuestions.map(q => ({
                    quiz: newQuiz._id,
                    type: q.type,
                    baseQuestion: q.baseQuestion,
                    imageUrl: q.imageUrl || '',
                    optionsTemplate: q.optionsTemplate || q.options || [],
                    correctAnswerTemplate: q.correctAnswerTemplate,
                    explanationTemplate: q.explanationTemplate,
                    solutionSteps: q.solutionSteps || [],
                    difficulty: 'easy'
                }));
                
                await Question.insertMany(questionDocs);
            }
        } catch (quizErr) {
            console.error("Auto-Quiz Generation Error:", quizErr);
            // Non-blocking
        }

        const io = req.app.get('io');
        if (io) {
            lesson.sections.forEach(sectionId => {
                io.emit('classroom_updated', {
                    action: 'lesson_created',
                    sectionId: sectionId.toString(),
                    subjectId: lesson.subject.toString(),
                    lessonId: lesson._id.toString(),
                });
            });
        }

        res.status(201).json(lesson);
    } catch (error) {
        console.error('Create Lesson Error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all lessons for the logged in user
// @route   GET /api/lessons
// @access  Private
exports.getLessons = async (req, res) => {
    try {
        let query = {};
        
        if (req.user.role === 'teacher') {
            query.teacher = req.user._id;
        } else if (req.user.role === 'student') {
            // Find section student belongs to
            const studentSection = await Section.findOne({ students: req.user._id });
            if (studentSection) {
                query.sections = studentSection._id;
            } else {
                return res.json([]); // No section assigned
            }
        }

        const lessons = await Lesson.find(query)
            .populate('teacher', 'name email')
            .populate('subject', 'name color');
        res.json(lessons);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get lesson by ID
// @route   GET /api/lessons/:id
// @access  Private
exports.getLessonById = async (req, res) => {
    try {
        const lesson = await Lesson.findById(req.params.id)
            .populate('teacher', 'name email')
            .populate('subject', 'name color');
        
        if (!lesson) {
            return res.status(404).json({ message: 'Lesson not found' });
        }

        res.json(lesson);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update a teacher-owned lesson
// @route   PUT /api/lessons/:id
// @access  Private (Teacher)
exports.updateLesson = async (req, res) => {
    try {
        const lesson = await Lesson.findById(req.params.id);
        if (!lesson) return res.status(404).json({ message: 'Lesson not found' });
        if (lesson.teacher.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'You can only update your own lessons.' });
        }

        const { title, subject, content, sections } = req.body;
        if (title !== undefined) lesson.title = title;
        if (subject !== undefined) lesson.subject = subject;
        if (content !== undefined && content.trim()) {
            lesson.content = content;
            const aiAnalysis = await analyzeLesson(content);
            lesson.summary = aiAnalysis.summary;
            lesson.objectives = aiAnalysis.learningObjectives;
        }
        if (sections !== undefined) {
            lesson.sections = Array.isArray(sections) ? sections : JSON.parse(sections);
        }

        await lesson.save();

        const io = req.app.get('io');
        if (io) {
            lesson.sections.forEach(sectionId => {
                io.emit('classroom_updated', {
                    action: 'lesson_updated',
                    sectionId: sectionId.toString(),
                    subjectId: lesson.subject.toString(),
                    lessonId: lesson._id.toString(),
                });
            });
        }

        res.json(lesson);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Delete a teacher-owned lesson and its quizzes/questions
// @route   DELETE /api/lessons/:id
// @access  Private (Teacher)
exports.deleteLesson = async (req, res) => {
    try {
        const lesson = await Lesson.findById(req.params.id);
        if (!lesson) return res.status(404).json({ message: 'Lesson not found' });
        if (lesson.teacher.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'You can only delete your own lessons.' });
        }

        const quizzes = await Quiz.find({ lesson: lesson._id }).select('_id');
        const quizIds = quizzes.map(q => q._id);
        await Question.deleteMany({ quiz: { $in: quizIds } });
        await Quiz.deleteMany({ _id: { $in: quizIds } });
        await lesson.deleteOne();

        const io = req.app.get('io');
        if (io) {
            lesson.sections.forEach(sectionId => {
                io.emit('classroom_updated', {
                    action: 'lesson_deleted',
                    sectionId: sectionId.toString(),
                    subjectId: lesson.subject.toString(),
                    lessonId: lesson._id.toString(),
                });
            });
        }

        res.json({ message: 'Lesson deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
