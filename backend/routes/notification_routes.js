const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const { protect, adminOnly } = require('../middleware/auth_middleware');

// Get all notifications (for a user or general)
router.get('/', async (req, res) => {
    try {
        const target = req.query.target || 'OVERALL';
        
        let query;
        if (target === 'ADMIN') {
            query = {}; // Admin sees all
        } else {
            query = { $or: [{ target: 'OVERALL' }, { target: target }] };
        }
        
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

// @desc    Update an announcement/notification (title, message, target)
// @route   PUT /api/notifications/:id
// @access  Private (Admin)
router.put('/:id', protect, adminOnly, async (req, res) => {
    try {
        const { title, message, target } = req.body;
        const update = {};
        if (title !== undefined) update.title = title;
        if (message !== undefined) update.message = message;
        if (target !== undefined) update.target = target;

        const notification = await Notification.findByIdAndUpdate(
            req.params.id,
            update,
            { new: true, runValidators: true }
        );

        if (!notification) {
            return res.status(404).json({ message: 'Notification not found' });
        }

        res.json(notification);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// @desc    Delete a notification
// @route   DELETE /api/notifications/:id
// @access  Private (Admin)
router.delete('/:id', protect, adminOnly, async (req, res) => {
    try {
        const notification = await Notification.findByIdAndDelete(req.params.id);

        if (!notification) {
            return res.status(404).json({ message: 'Notification not found' });
        }

        res.json({ message: 'Notification removed' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
