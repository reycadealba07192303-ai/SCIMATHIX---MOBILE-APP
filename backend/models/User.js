const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    firebaseUid: {
        type: String,
        unique: true,
        sparse: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    password: {
        type: String,
        required: true
    },
    role: {
        type: String,
        enum: ['student', 'teacher', 'admin'],
        default: 'student'
    },
    // Student specific fields
    section: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Section'
    },
    xp: {
        type: Number,
        default: 0
    },
    achievements: [{
        title: String,
        date: { type: Date, default: Date.now }
    }],
    // Teacher specific fields
    specialty: {
        type: String,
        enum: ['Mathematics', 'Science', null],
        default: null
    },
    subjects: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Subject'
    }],
    handledClasses: [{
        section: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Section'
        },
        subject: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Subject'
        }
    }],
    isApproved: {
        type: Boolean,
        default: false
    },
    isActive: {
        type: Boolean,
        default: true
    },
    profilePicture: {
        type: String,
        default: ''
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Hash password before saving
userSchema.pre('save', async function() {
    if (!this.isModified('password')) return;
    this.password = await bcrypt.hash(this.password, 10);
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
