const User = require('../models/User');
const generateToken = require('../config/generateToken');
const { createLog } = require('../utils/logger');

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
exports.registerUser = async (req, res) => {
    const { name, email, password, role, section, firebaseUid } = req.body;

    try {
        const userExists = await User.findOne({ email });

        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        const user = await User.create({
            name,
            email,
            password,
            firebaseUid,
            role: role || 'student',
            section: role === 'student' ? section : undefined,
            isApproved: true // Verification handled via email
        });

        if (user) {
            // Log registration event
            await createLog(req, {
                user: user.name,
                role: user.role,
                action: 'Registered a new account',
                icon: 'login',
                color: 'green'
            });

            res.status(201).json({
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                isApproved: user.isApproved,
                token: generateToken(user._id)
            });
        } else {
            res.status(400).json({ message: 'Invalid user data' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
exports.loginUser = async (req, res) => {
    const { email, password } = req.body;

    try {
        const user = await User.findOne({ email })
            .populate({
                path: 'handledClasses.section',
                select: 'name level',
                populate: { path: 'level', select: 'name' }
            })
            .populate({
                path: 'handledClasses.subject',
                select: 'name code'
            });

        if (user && (await user.comparePassword(password))) {
            // Log login event
            await createLog(req, {
                user: user.name,
                role: user.role,
                action: 'Logged into the system',
                icon: 'login',
                color: 'blue'
            });

            res.json({
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                section: user.section,
                xp: user.xp,
                profilePicture: user.profilePicture,
                handledClasses: user.handledClasses,
                token: generateToken(user._id)
            });
        } else {
            // Log failed login attempt
            await createLog(req, {
                user: email,
                role: 'unknown',
                action: 'Failed login attempt',
                icon: 'warning',
                color: 'red'
            });

            res.status(401).json({ message: 'Invalid email or password' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Upload profile picture
// @route   POST /api/auth/profile-picture
// @access  Private
exports.updateProfilePicture = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const filename = req.file.filename;
        const user = await User.findByIdAndUpdate(
            req.user._id,
            { profilePicture: filename },
            { new: true }
        );

        res.json({ profilePicture: user.profilePicture });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
