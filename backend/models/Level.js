const mongoose = require('mongoose');

const levelSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
    },
    schoolYear: {
        type: String,
        required: true,
        default: "2026-2027"
    },
    order: {
        type: Number,
        default: 0
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

levelSchema.index({ name: 1, schoolYear: 1 }, { unique: true });

module.exports = mongoose.model('Level', levelSchema);
