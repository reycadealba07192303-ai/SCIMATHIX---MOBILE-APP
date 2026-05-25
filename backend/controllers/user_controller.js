const User = require('../models/User');
const admin = require('../config/firebase');

// @desc    Get all users (Admin only)
// @route   GET /api/users
// @access  Private/Admin
exports.getAllUsers = async (req, res) => {
    try {
        const users = await User.find({}).select('-password');
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a user (Admin only)
// @route   POST /api/users
// @access  Private/Admin
exports.createUser = async (req, res) => {
    try {
        const { name, email, password, role } = req.body;

        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        const user = await User.create({
            name,
            email,
            password,
            role: role || 'student',
            isApproved: true // Admin created, so implicitly approved
        });

        res.status(201).json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// @desc    Update a user
// @route   PUT /api/users/:id
// @access  Private/Admin
exports.updateUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        user.name = req.body.name || user.name;
        user.email = req.body.email || user.email;
        user.role = req.body.role || user.role;

        if (req.body.password) {
            user.password = req.body.password;
        }

        const updatedUser = await user.save();
        res.json({
            _id: updatedUser._id,
            name: updatedUser.name,
            email: updatedUser.email,
            role: updatedUser.role,
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// @desc    Delete a user
// @route   DELETE /api/users/:id
// @access  Private/Admin
exports.deleteUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Delete from Firebase Auth if firebaseUid exists and admin is initialized
        if (user.firebaseUid && admin.apps.length > 0) {
            try {
                await admin.auth().deleteUser(user.firebaseUid);
                console.log(`Successfully deleted user from Firebase Auth: ${user.firebaseUid}`);
            } catch (firebaseError) {
                console.error("Error deleting user from Firebase Auth:", firebaseError);
                // Continue to delete from MongoDB even if Firebase fails
            }
        } else if (user.firebaseUid && admin.apps.length === 0) {
             console.warn("WARNING: Firebase Admin not initialized. User not deleted from Firebase.");
        }

        await User.findByIdAndDelete(req.params.id);
        res.json({ message: 'User removed from Database and Firebase' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
