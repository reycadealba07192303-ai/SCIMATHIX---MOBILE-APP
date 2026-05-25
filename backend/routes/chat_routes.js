const express = require('express');
const router = express.Router();
const { sendMessage, getChatHistory } = require('../controllers/chat_controller');
const { protect } = require('../middleware/auth_middleware');

router.post('/', protect, sendMessage);
router.get('/:lessonId', protect, getChatHistory);

module.exports = router;
