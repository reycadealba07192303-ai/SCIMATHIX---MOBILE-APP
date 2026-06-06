const Announcement = require('../models/Announcement');
const Quiz = require('../models/Quiz');
const Lesson = require('../models/Lesson');
const Section = require('../models/Section');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { createLog } = require('../utils/logger');

exports.createAnnouncement = async (req, res) => {
    try {
        const { title, content, scheduledDate, scheduledTime, sectionId, subjectId } = req.body;

        // subjectId is optional — if provided, verify teacher is assigned
        if (subjectId) {
            const canPost = await User.exists({
                _id: req.user._id,
                handledClasses: {
                    $elemMatch: {
                        section: sectionId,
                        subject: subjectId,
                    }
                }
            });

            if (!canPost) {
                return res.status(403).json({ message: 'You can only announce in subjects assigned to you.' });
            }
        }

        const announcement = await Announcement.create({
            title,
            content,
            scheduledDate,
            scheduledTime,
            teacher: req.user._id,
            section: sectionId,
            subject: subjectId,
        });

        // Create a notification for this announcement
        const notif = await Notification.create({
            title: 'New Announcement',
            message: content.substring(0, 200),
            target: 'SPECIFIC_USER',
            recipientId: req.user._id,
            type: 'classroom_announcement'
        });

        const io = req.app.get('io');
        if (io) {
            io.emit('new_notification', notif);
            io.emit('classroom_updated', {
                action: 'announcement_created',
                sectionId,
                subjectId,
                teacherId: req.user._id.toString(),
                announcement,
            });
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
        const { subjectId } = req.query;

        let announcementQuery = { section: sectionId };
        let lessonQuery = { sections: sectionId };

        if (subjectId) {
            const assignedTeachers = await User.find({
                role: 'teacher',
                handledClasses: {
                    $elemMatch: {
                        section: sectionId,
                        subject: subjectId,
                    }
                }
            }).select('_id');

            const assignedTeacherIds = assignedTeachers.map(t => t._id);
            announcementQuery = {
                section: sectionId,
                $or: [
                    { subject: subjectId },
                    { subject: { $exists: false }, teacher: { $in: assignedTeacherIds } },
                    { subject: null, teacher: { $in: assignedTeacherIds } },
                ]
            };
            lessonQuery.subject = subjectId;
        }
        
        // Fetch announcements for this section/subject
        const announcements = await Announcement.find(announcementQuery)
            .populate('teacher', 'name')
            .populate('subject', 'name code category')
            .lean();
            
        // Fetch lessons for this section/subject
        const lessons = await Lesson.find(lessonQuery)
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

// @desc    Get calendar feed for a section
// @route   GET /api/announcements/calendar/:sectionId
// @access  Private
exports.getCalendarFeed = async (req, res) => {
    try {
        const { sectionId } = req.params;

        // 1. Section-scoped announcements that have a scheduled date
        const announcements = await Announcement.find({
            section: sectionId,
            scheduledDate: { $ne: null, $exists: true },
        })
            .populate('teacher', 'name')
            .populate('subject', 'name code category')
            .sort({ scheduledDate: 1 })
            .lean();

        // 2. Admin-created system-wide notifications of type 'announcement'.
        //    The Notification model has no dedicated scheduledDate field, so we
        //    treat its `timestamp` as the date info for the calendar.
        const adminNotifications = await Notification.find({
            type: 'announcement',
            target: { $in: ['OVERALL', 'STUDENT ONLY'] },
            timestamp: { $ne: null, $exists: true },
        })
            .sort({ timestamp: 1 })
            .lean();

        const sectionEvents = announcements.map((a) => ({
            _id: a._id,
            source: 'announcement',
            title: a.title || 'Announcement',
            content: a.content,
            scheduledDate: a.scheduledDate,
            scheduledTime: a.scheduledTime || null,
            teacher: a.teacher || null,
            subject: a.subject || null,
            section: a.section,
            createdAt: a.createdAt,
        }));

        const adminEvents = adminNotifications.map((n) => ({
            _id: n._id,
            source: 'notification',
            title: n.title,
            content: n.message,
            scheduledDate: n.timestamp,
            scheduledTime: null,
            teacher: null,
            subject: null,
            section: null,
            createdAt: n.timestamp,
        }));

        // 3. Quizzes scheduled for this section
        const lessons = await Lesson.find({ sections: sectionId }).select('_id');
        const lessonIds = lessons.map(l => l._id);
        const quizzes = await Quiz.find({
            lesson: { $in: lessonIds },
            scheduledDate: { $ne: null, $exists: true }
        })
            .populate('teacher', 'name')
            .populate({ path: 'lesson', select: 'title subject', populate: { path: 'subject', select: 'name code category' } })
            .lean();

        const quizEvents = quizzes.map((q) => ({
            _id: q._id,
            source: 'quiz',
            title: q.title || 'Quiz',
            content: `Quiz for ${q.lesson?.title || 'Lesson'}`,
            scheduledDate: q.scheduledDate,
            scheduledTime: q.scheduledTime || null,
            endTime: q.endTime || null,
            teacher: q.teacher || null,
            subject: q.lesson?.subject || null,
            section: sectionId,
            createdAt: q.createdAt,
        }));

        const events = [...sectionEvents, ...adminEvents, ...quizEvents].sort((a, b) => {
            return new Date(a.scheduledDate) - new Date(b.scheduledDate);
        });

        res.json(events);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update an announcement
// @route   PUT /api/announcements/:id
// @access  Private (Teacher)
exports.updateAnnouncement = async (req, res) => {
    try {
        const { title, content, scheduledDate, scheduledTime } = req.body;
        const announcement = await Announcement.findById(req.params.id);

        if (!announcement) {
            return res.status(404).json({ message: 'Announcement not found' });
        }

        if (announcement.teacher.toString() !== req.user._id.toString()) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        if (title !== undefined) announcement.title = title;
        if (content !== undefined) announcement.content = content;
        if (scheduledDate !== undefined) announcement.scheduledDate = scheduledDate;
        if (scheduledTime !== undefined) announcement.scheduledTime = scheduledTime;

        const updatedAnnouncement = await announcement.save();

        // Notify students in the section so their UI auto-syncs
        const io = req.app.get('io');
        if (io) {
            io.emit('classroom_updated', {
                action: 'announcement_updated',
                sectionId: announcement.section ? announcement.section.toString() : null,
                subjectId: announcement.subject ? announcement.subject.toString() : null,
                announcementId: announcement._id.toString(),
            });
        }

        res.json(updatedAnnouncement);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Delete an announcement
// @route   DELETE /api/announcements/:id
// @access  Private (Teacher)
exports.deleteAnnouncement = async (req, res) => {
    try {
        const announcement = await Announcement.findById(req.params.id);

        if (!announcement) {
            return res.status(404).json({ message: 'Announcement not found' });
        }

        if (announcement.teacher.toString() !== req.user._id.toString()) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        const sectionId = announcement.section ? announcement.section.toString() : null;
        const subjectId = announcement.subject ? announcement.subject.toString() : null;

        await announcement.deleteOne();

        // Notify students in the section so their UI auto-syncs
        const io = req.app.get('io');
        if (io) {
            io.emit('classroom_updated', {
                action: 'announcement_deleted',
                sectionId,
                subjectId,
                announcementId: req.params.id,
            });
        }

        res.json({ message: 'Announcement removed' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
