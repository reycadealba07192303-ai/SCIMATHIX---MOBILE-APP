const express = require('express');
const router = express.Router();
const { getLeaderboard, getSectionTrends } = require('../controllers/analytics_controller');
const { protect, teacherOnly } = require('../middleware/auth_middleware');

router.get('/leaderboard/:sectionId', protect, getLeaderboard);
router.get('/weak-topics', protect, require('../controllers/analytics_controller').getWeakTopics);
router.get('/trends/:sectionId', protect, teacherOnly, getSectionTrends);
router.get('/admin-reports', protect, require('../controllers/analytics_controller').getAdminReports);

module.exports = router;
