const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { registerUser, loginUser, updateProfilePicture } = require('../controllers/auth_controller');
const { protect } = require('../middleware/auth_middleware');

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, `profile_${req.user._id}${path.extname(file.originalname)}`)
});
const upload = multer({ storage });

router.post('/register', registerUser);
router.post('/login', loginUser);
router.post('/profile-picture', protect, upload.single('profilePicture'), updateProfilePicture);

module.exports = router;
