const Message = require('../models/Message');
const Lesson = require('../models/Lesson');
const axios = require('axios');

const truncateText = (text, maxLength = 12000) => {
    if (!text) return '';
    return text.length > maxLength
        ? `${text.slice(0, maxLength)}\n\n[Lesson content truncated for length.]`
        : text;
};

exports.sendMessage = async (req, res) => {
    let { content, lessonId, conversationId } = req.body;

    if (lessonId === 'ai_assistant' || lessonId === 'null') {
        lessonId = null;
    }

    // For the general AI assistant, group messages by conversationId so the
    // student can keep multiple separate conversations and a history list.
    if (!conversationId) {
        conversationId = `conv_${req.user._id}_${Date.now()}`;
    }

    try {
        let lessonContext = '';
        if (lessonId) {
            const lesson = await Lesson.findById(lessonId).select('title content summary objectives');
            if (lesson) {
                lessonContext = [
                    `Lesson Title: ${lesson.title}`,
                    lesson.summary ? `Lesson Summary: ${lesson.summary}` : '',
                    lesson.objectives?.length ? `Learning Objectives:\n${lesson.objectives.map((objective, index) => `${index + 1}. ${objective}`).join('\n')}` : '',
                    lesson.content ? `Lesson Content:\n${truncateText(lesson.content)}` : '',
                ].filter(Boolean).join('\n\n');
            }
        }

        // 1. Save User Message
        const userMessage = await Message.create({
            student: req.user._id,
            lesson: lessonId,
            conversationId,
            role: 'user',
            content: content
        });

        // 2. Fetch History for Context (scoped to this conversation thread)
        const historyFilter = { student: req.user._id, lesson: lessonId };
        if (conversationId) historyFilter.conversationId = conversationId;
        const history = await Message.find(historyFilter)
            .sort({ createdAt: -1 })
            .limit(10);
        
        const contextMessages = history.reverse().map(m => ({
            role: m.role,
            content: m.content
        }));

        let aiContent = "I'm sorry, I couldn't process that right now.";
        
        if (process.env.GEMINI_API_KEY) {
            const systemPrompt = "You are a strict, helpful study assistant for SCIMATHIX. You must ONLY answer questions related to Science and Mathematics. Your answers must be simple, easy to understand, and strictly tailored for a Grade 9 student level. When Lesson Context is provided, treat it as the current file/lesson the student is asking about. If the student says 'this', 'the file', or 'the lesson', use the Lesson Context. If a student asks about anything outside of Math, Science, or the current lesson context, politely decline and remind them to stay on topic.";
            
            // Format messages for Gemini (requires alternating user/model roles, but we'll simplify to just system instruction + chat history string)
            const formattedHistory = contextMessages.map(m => `${m.role.toUpperCase()}: ${m.content}`).join('\n');
            const prompt = `${systemPrompt}\n\nLesson Context:\n${lessonContext || 'No specific lesson context was provided.'}\n\nChat History:\n${formattedHistory}\n\nASSISTANT:`;

            const response = await axios.post(
                `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
                { contents: [{ parts: [{ text: prompt }] }] },
                { timeout: 25000 }
            );

            aiContent = response.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim()
                || "I'm sorry, I couldn't generate a response. Please try again.";
        } else {
            aiContent = "As an AI, I can help you understand this lesson better. What specifically would you like to know?";
        }

        // 4. Save AI Response
        const assistantMessage = await Message.create({
            student: req.user._id,
            lesson: lessonId,
            conversationId,
            role: 'assistant',
            content: aiContent
        });

        res.json({ userMessage, assistantMessage, conversationId });
    } catch (error) {
        console.error('AI Chat Error:', error.response ? error.response.data : error.message);
        res.status(500).json({ message: 'The AI assistant is unavailable right now. Please try again.' });
    }
};

// @desc    List AI conversations for the logged-in student
// @route   GET /api/chat/conversations/list
// @access  Private
exports.getConversations = async (req, res) => {
    try {
        const messages = await Message.find({
            student: req.user._id,
            lesson: null,
            conversationId: { $ne: null },
        }).sort({ createdAt: -1 }).lean();

        const map = new Map();
        for (const m of messages) {
            if (!map.has(m.conversationId)) {
                map.set(m.conversationId, {
                    conversationId: m.conversationId,
                    lastMessage: m.content,
                    lastRole: m.role,
                    updatedAt: m.createdAt,
                    // First user message becomes the title preview
                    title: m.role === 'user' ? m.content : null,
                });
            } else if (m.role === 'user') {
                // Keep updating the title to the earliest user message (we iterate newest-first)
                map.get(m.conversationId).title = m.content;
            }
        }

        const conversations = Array.from(map.values()).map(c => ({
            ...c,
            title: (c.title || 'New Conversation').toString().slice(0, 60),
        }));

        res.json(conversations);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getChatHistory = async (req, res) => {
    try {
        let lessonId = req.params.lessonId;
        if (lessonId === 'ai_assistant' || lessonId === 'null') {
            lessonId = null;
        }

        const filter = { student: req.user._id, lesson: lessonId };
        // Optional conversation scoping for the general AI assistant
        if (req.query.conversationId) {
            filter.conversationId = req.query.conversationId;
        }

        const history = await Message.find(filter)
            .sort({ createdAt: 1 });
        res.json(history);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const DirectMessage = require('../models/DirectMessage');

exports.sendDirectMessage = async (req, res) => {
    const { content, receiverId } = req.body;
    try {
        const message = await DirectMessage.create({
            sender: req.user._id,
            receiver: receiverId,
            content
        });
        const io = req.app.get('io');
        if (io) {
            io.emit('direct_message', {
                _id: message._id,
                sender: message.sender,
                receiver: message.receiver,
                content: message.content,
                createdAt: message.createdAt,
            });
        }
        res.status(201).json(message);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getDirectMessageHistory = async (req, res) => {
    try {
        const history = await DirectMessage.find({
            $or: [
                { sender: req.user._id, receiver: req.params.userId },
                { sender: req.params.userId, receiver: req.user._id }
            ]
        }).sort({ createdAt: 1 });
        res.json(history);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
