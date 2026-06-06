const mongoose = require('mongoose');

const quizSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    lesson: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Lesson'
    },
    teacher: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    timeLimit: {
        type: Number, // In minutes
        default: 30
    },
    passingScore: {
        type: Number,
        default: 50 // Percentage
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isPractice: {
        type: Boolean,
        default: false
    },
    difficulty: {
        type: String,
        enum: ['easy', 'medium', 'hard'],
        default: 'easy'
    },
    scheduledDate: {
        type: Date,
        required: false
    },
    scheduledTime: {
        type: String,
        required: false
    },
    endTime: {
        type: String,
        required: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Quiz', quizSchema);
