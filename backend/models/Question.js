const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
    quiz: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Quiz',
        required: true
    },
    type: {
        type: String,
        enum: ['multiple-choice', 'identification', 'problem-solving'],
        required: true
    },
    baseQuestion: {
        type: String, // e.g., "Solve for x: {v1}x + {v2} = {v3}"
        required: true
    },
    variables: {
        type: Map,
        of: [Number], // e.g., { "v1": [2, 3, 5], "v2": [5, 10], "v3": [15, 20] }
        default: {}
    },
    correctAnswerTemplate: {
        type: String, // e.g., "({v3} - {v2}) / {v1}"
        required: true
    },
    optionsTemplate: [{
        type: String // For multiple choice
    }],
    explanationTemplate: String, // AI Generated step-by-step logic
    difficulty: {
        type: String,
        enum: ['easy', 'medium', 'hard'],
        default: 'medium'
    }
});

module.exports = mongoose.model('Question', questionSchema);
