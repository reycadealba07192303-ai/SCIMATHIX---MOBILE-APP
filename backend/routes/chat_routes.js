const express = require('express');
const router = express.Router();
const { sendMessage, getChatHistory, getConversations, sendDirectMessage, getDirectMessageHistory } = require('../controllers/chat_controller');
const { protect } = require('../middleware/auth_middleware');

// Direct messaging routes MUST come before /:lessonId to avoid being swallowed by the param route
router.post('/direct', protect, sendDirectMessage);
router.get('/direct/:userId', protect, getDirectMessageHistory);

// AI conversation list (specific path before the param route)
router.get('/conversations/list', protect, getConversations);

router.post('/', protect, sendMessage);
router.get('/:lessonId', protect, getChatHistory);

module.exports = router;
