const express = require('express');
const router = express.Router();
const { protect, teacherOnly } = require('../middleware/auth_middleware');
const { createAnnouncement, getClassroomFeed } = require('../controllers/announcement_controller');

router.post('/', protect, teacherOnly, createAnnouncement);
router.get('/feed/:sectionId', protect, getClassroomFeed);

module.exports = router;
