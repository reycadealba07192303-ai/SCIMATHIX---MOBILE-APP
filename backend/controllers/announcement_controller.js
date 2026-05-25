const Announcement = require('../models/Announcement');
const Lesson = require('../models/Lesson');
const Section = require('../models/Section');
const Notification = require('../models/Notification');
const { createLog } = require('../utils/logger');

exports.createAnnouncement = async (req, res) => {
    try {
        const { content, sectionId } = req.body;
        
        // Ensure section belongs to teacher (optional check)
        const announcement = await Announcement.create({
            content,
            teacher: req.user._id,
            section: sectionId
        });

        // Create a notification for this announcement
        const notif = await Notification.create({
            title: 'New Announcement',
            message: content.substring(0, 200),
            target: 'OVERALL',
            type: 'announcement'
        });

        const io = req.app.get('io');
        if (io) {
            io.emit('new_notification', notif);
        }

        // Log the action
        await createLog(req, {
            user: req.user.name,
            role: req.user.role,
            action: 'Published a new announcement',
            icon: 'book',
            color: 'purple'
        });
        
        res.status(201).json(announcement);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.getClassroomFeed = async (req, res) => {
    try {
        const { sectionId } = req.params;
        
        // Fetch announcements for this section
        const announcements = await Announcement.find({ section: sectionId })
            .populate('teacher', 'name')
            .lean();
            
        // Fetch lessons for this section
        const lessons = await Lesson.find({ sections: sectionId })
            .populate('teacher', 'name')
            .populate('subject', 'name')
            .lean();
            
        // Add type tags
        const formattedAnnouncements = announcements.map(a => ({
            ...a,
            feedType: 'announcement'
        }));
        
        const formattedLessons = lessons.map(l => ({
            ...l,
            feedType: 'lesson'
        }));
        
        // Combine and sort by date descending
        const feed = [...formattedAnnouncements, ...formattedLessons].sort((a, b) => {
            return new Date(b.createdAt) - new Date(a.createdAt);
        });
        
        res.json(feed);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
