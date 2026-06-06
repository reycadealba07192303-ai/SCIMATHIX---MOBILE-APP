const express = require('express');
const router = express.Router();
const {
    createAIQuiz,
    getQuizForStudent,
    submitQuiz,
    getQuizzes,
    getQuizById,
    updateQuiz,
    deleteQuiz,
    getQuizByLesson,
    getLeaderboard,
    getQuizSubmissions,
} = require('../controllers/quiz_controller');
const { protect, teacherOnly } = require('../middleware/auth_middleware');

router.post('/generate', protect, teacherOnly, createAIQuiz);
router.get('/', protect, getQuizzes);
router.get('/leaderboard', protect, getLeaderboard);
router.get('/lesson/:lessonId', protect, getQuizByLesson);
router.get('/:id/take', protect, getQuizForStudent);
router.post('/:id/submit', protect, submitQuiz);
router.get('/:id/submissions', protect, teacherOnly, getQuizSubmissions);
router.get('/:id', protect, teacherOnly, getQuizById);
router.put('/:id', protect, teacherOnly, updateQuiz);
router.delete('/:id', protect, teacherOnly, deleteQuiz);

module.exports = router;
