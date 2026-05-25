const Message = require('../models/Message');
const axios = require('axios');

exports.sendMessage = async (req, res) => {
    const { content, lessonId } = req.body;

    try {
        // 1. Save User Message
        const userMessage = await Message.create({
            student: req.user._id,
            lesson: lessonId,
            role: 'user',
            content: content
        });

        // 2. Fetch History for Context
        const history = await Message.find({ student: req.user._id, lesson: lessonId })
            .sort({ createdAt: -1 })
            .limit(10);
        
        const contextMessages = history.reverse().map(m => ({
            role: m.role,
            content: m.content
        }));

        // 3. Call AI Service (Simplified here, should be in ai_service)
        let aiContent = "I'm sorry, I couldn't process that right now.";
        
        if (process.env.DEEPSEEK_API_KEY) {
            const response = await axios.post('https://api.deepseek.com/v1/chat/completions', {
                model: "deepseek-chat",
                messages: [
                    { role: "system", content: "You are a helpful study assistant for SCIMATHNIX." },
                    ...contextMessages
                ]
            }, {
                headers: { 'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}` }
            });
            aiContent = response.data.choices[0].message.content;
        } else {
            aiContent = "As an AI, I can help you understand this lesson better. What specifically would you like to know?";
        }

        // 4. Save AI Response
        const assistantMessage = await Message.create({
            student: req.user._id,
            lesson: lessonId,
            role: 'assistant',
            content: aiContent
        });

        res.json({ userMessage, assistantMessage });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getChatHistory = async (req, res) => {
    try {
        const history = await Message.find({ student: req.user._id, lesson: req.params.lessonId })
            .sort({ createdAt: 1 });
        res.json(history);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
