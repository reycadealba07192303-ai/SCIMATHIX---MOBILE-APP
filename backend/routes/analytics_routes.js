const express = require('express');
const router = express.Router();
const { getLeaderboard, getSectionTrends } = require('../controllers/analytics_controller');
const { protect, teacherOnly } = require('../middleware/auth_middleware');

router.get('/leaderboard/:sectionId', protect, getLeaderboard);
router.get('/weak-topics', protect, require('../controllers/analytics_controller').getWeakTopics);
router.get('/trends/:sectionId', protect, teacherOnly, getSectionTrends);
router.get('/admin-reports', protect, require('../controllers/analytics_controller').getAdminReports);
router.get('/teacher-reports', protect, require('../controllers/analytics_controller').getTeacherReports);
router.get('/teacher/section-performance', protect, teacherOnly, require('../controllers/analytics_controller').getTeacherSectionPerformance);
router.get('/teacher/weak-topics', protect, teacherOnly, require('../controllers/analytics_controller').getTeacherWeakTopics);
router.get('/teacher/monitoring', protect, teacherOnly, require('../controllers/analytics_controller').getTeacherMonitoring);
router.get('/student/stats', protect, require('../controllers/analytics_controller').getStudentStats);

module.exports = router;
