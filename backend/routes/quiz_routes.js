const express = require('express');
const router = express.Router();
const { createAIQuiz, getQuizForStudent, submitQuiz } = require('../controllers/quiz_controller');
const { protect, teacherOnly } = require('../middleware/auth_middleware');

router.post('/generate', protect, teacherOnly, createAIQuiz);
router.get('/', protect, require('../controllers/quiz_controller').getQuizzes);
router.get('/:id/take', protect, getQuizForStudent);
router.post('/:id/submit', protect, submitQuiz);
router.get('/leaderboard', protect, require('../controllers/quiz_controller').getLeaderboard);

module.exports = router;
