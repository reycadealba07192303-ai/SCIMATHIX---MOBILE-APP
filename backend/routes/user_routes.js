const express = require('express');
const router = express.Router();
const { protect, adminOnly } = require('../middleware/auth_middleware');
const {
    getAllUsers,
    createUser,
    updateUser,
    deleteUser,
    updateProfileImage,
    updateOwnProfile
} = require('../controllers/user_controller');

const upload = require('../middleware/upload_middleware');

router.route('/profile')
    .put(protect, updateOwnProfile);

router.route('/profile-image')
    .put(protect, upload.single('image'), updateProfileImage);

router.route('/')
    .get(protect, adminOnly, getAllUsers)
    .post(protect, adminOnly, createUser);

router.route('/:id')
    .put(protect, adminOnly, updateUser)
    .delete(protect, adminOnly, deleteUser);

module.exports = router;
