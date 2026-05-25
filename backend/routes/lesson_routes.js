const express = require('express');
const router = express.Router();
const { createLesson, getLessons, getLessonById } = require('../controllers/lesson_controller');
const { protect, teacherOnly } = require('../middleware/auth_middleware');

const upload = require('../middleware/upload_middleware');
const { cloudUpload } = require('../services/cloudinary_service');

// Use Cloudinary if keys are present, otherwise use local storage
const uploadMiddleware = (process.env.CLOUDINARY_CLOUD_NAME) ? cloudUpload : upload;

router.route('/')
    .get(protect, getLessons)
    .post(protect, teacherOnly, uploadMiddleware.single('file'), createLesson);

router.route('/:id')
    .get(protect, getLessonById);

module.exports = router;
