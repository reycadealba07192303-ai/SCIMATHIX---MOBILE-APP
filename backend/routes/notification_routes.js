const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');

// Get all notifications (for a user or general)
router.get('/', async (req, res) => {
    try {
        const target = req.query.target || 'OVERALL';
        // For simplicity, fetch global notifications or by target
        const query = { $or: [{ target: 'OVERALL' }, { target: target }] };
        const notifications = await Notification.find(query).sort({ timestamp: -1 }).limit(50);
        res.json(notifications);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create a new notification
router.post('/', async (req, res) => {
    try {
        const { title, message, target, type } = req.body;
        const newNotification = new Notification({
            title,
            message,
            target: target || 'OVERALL',
            type: type || 'system'
        });
        await newNotification.save();

        const io = req.app.get('io');
        if (io) {
            io.emit('new_notification', newNotification);
        }

        res.status(201).json(newNotification);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Mark as read
router.put('/:id/read', async (req, res) => {
    try {
        const notification = await Notification.findByIdAndUpdate(req.params.id, { isRead: true }, { new: true });
        res.json(notification);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
