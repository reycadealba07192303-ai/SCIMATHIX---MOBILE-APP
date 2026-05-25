const Lesson = require('../models/Lesson');
const Section = require('../models/Section');
const fs = require('fs');
const pdf = require('pdf-parse');
const { analyzeLesson } = require('../services/ai_service');

// @desc    Create a new lesson with AI analysis
// @route   POST /api/lessons
// @access  Private (Teacher/Admin)
exports.createLesson = async (req, res) => {
    const { title, subject, content: manualContent, sections } = req.body;
    let extractedContent = manualContent || "";

    try {
        // 1. Handle File Upload & Text Extraction
        let fileUrl = "";
        if (req.file) {
            fileUrl = `/uploads/${req.file.filename}`;
            
            // If it's a PDF, extract text
            if (req.file.mimetype === 'application/pdf') {
                const dataBuffer = fs.readFileSync(req.file.path);
                const data = await pdf(dataBuffer);
                extractedContent = data.text;
            }
        }

        if (!extractedContent) {
            return res.status(400).json({ message: "No content provided (manually or via file)" });
        }

        // 2. Perform AI Analysis (Summary & Objectives)
        const aiAnalysis = await analyzeLesson(extractedContent);

        // 3. Create Lesson in Database
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
