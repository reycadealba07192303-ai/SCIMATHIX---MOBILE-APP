const express = require('express');
const router = express.Router();
const { protect, teacherOnly } = require('../middleware/auth_middleware');
const { createAnnouncement, getClassroomFeed, getCalendarFeed, updateAnnouncement, deleteAnnouncement } = require('../controllers/announcement_controller');

router.post('/', protect, teacherOnly, createAnnouncement);
router.put('/:id', protect, teacherOnly, updateAnnouncement);
router.delete('/:id', protect, teacherOnly, deleteAnnouncement);
router.get('/feed/:sectionId', protect, getClassroomFeed);
router.get('/calendar/:sectionId', protect, getCalendarFeed);

module.exports = router;
