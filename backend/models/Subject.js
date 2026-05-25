const mongoose = require('mongoose');

const subjectSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    code: {
        type: String,
        required: true,
        unique: true // e.g., "MATH-101"
    },
    category: {
        type: String,
        enum: ['Mathematics', 'Science'],
        default: 'Mathematics'
    },
    description: {
        type: String
    },
    color: {
        type: String,
        default: '#2196F3'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Subject', subjectSchema);
