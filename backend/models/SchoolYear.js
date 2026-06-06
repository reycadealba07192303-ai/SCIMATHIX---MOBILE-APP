const mongoose = require('mongoose');

const schoolYearSchema = new mongoose.Schema({
    year: {
        type: String,
        required: true,
        unique: true // e.g., "2026-2027"
    },
    isActive: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('SchoolYear', schoolYearSchema);
