const Level = require('../models/Level');
const Section = require('../models/Section');
const Subject = require('../models/Subject');
const User = require('../models/User');
const SchoolYear = require('../models/SchoolYear');
const Notification = require('../models/Notification');
const admin = require('../config/firebase');

// --- School Year Controllers ---

exports.createSchoolYear = async (req, res) => {
    try {
        const sy = await SchoolYear.create(req.body);
        const io = req.app.get('io');
        if (io) io.emit('academic_updated', { action: 'school_year_created', schoolYearId: sy._id.toString() });
        res.status(201).json(sy);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.getSchoolYears = async (req, res) => {
    try {
        const sys = await SchoolYear.find().sort({ year: -1 }); // Descending order
        res.json(sys);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- Level Controllers ---

exports.createLevel = async (req, res) => {
    try {
        const level = await Level.create(req.body);
        const io = req.app.get('io');
        if (io) io.emit('academic_updated', { action: 'level_created', levelId: level._id.toString() });
        res.status(201).json(level);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.getLevels = async (req, res) => {
    try {
        const query = req.query.schoolYear ? { schoolYear: req.query.schoolYear } : {};
        const levels = await Level.find(query).sort('order');
        res.json(levels);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- Section Controllers ---

exports.createSection = async (req, res) => {
    try {
        const section = await Section.create(req.body);
        const io = req.app.get('io');
        if (io) io.emit('academic_updated', { action: 'section_created', sectionId: section._id.toString() });
        res.status(201).json(section);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};
exports.getSectionsByLevel = async (req, res) => {
    try {
        const sections = await Section.find({ level: req.params.levelId })
            .populate('teacher', 'name email')
            .populate('students', 'name email');
        res.json(sections);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getMySections = async (req, res) => {
    try {
        const teacher = await User.findById(req.user._id)
            .populate({
                path: 'handledClasses.section',
                select: 'name level students',
                populate: { path: 'level', select: 'name' }
            })
            .populate('handledClasses.subject', 'name code category');

        if (!teacher) return res.status(404).json({ message: 'Teacher not found' });

        const handledClasses = teacher.handledClasses
            .filter(hc => hc.section && hc.subject)
            .filter(hc => !teacher.specialty || hc.subject.category === teacher.specialty)
            .map(hc => ({
                _id: hc._id,
                section: hc.section,
                subject: hc.subject,
            }));

        res.json(handledClasses);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getSectionDetails = async (req, res) => {
    try {
        const section = await Section.findById(req.params.sectionId)
            .populate('teacher', 'name email')
            .populate('students', 'name email')
            .populate('subjects')
            .populate('level', 'name');
        if (!section) return res.status(404).json({ message: 'Section not found' });

        const teachers = await User.find({
            role: 'teacher',
            'handledClasses.section': section._id,
        }).select('name email specialty handledClasses');

        const subjectCategoryById = {};
        section.subjects.forEach(subject => {
            subjectCategoryById[subject._id.toString()] = subject.category;
        });

        const subjectTeachers = {};
        teachers.forEach(teacher => {
            teacher.handledClasses.forEach(hc => {
                const subjectId = hc.subject ? hc.subject.toString() : null;
                if (
                    hc.section &&
                    hc.subject &&
                    hc.section.toString() === section._id.toString() &&
                    (!teacher.specialty || subjectCategoryById[subjectId] === teacher.specialty)
                ) {
                    subjectTeachers[subjectId] = {
                        _id: teacher._id,
                        name: teacher.name,
                        email: teacher.email,
                        specialty: teacher.specialty,
                    };
                }
            });
        });

        res.json({
            ...section.toObject(),
            subjectTeachers,
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.assignTeacherToSection = async (req, res) => {
    try {
        const { sectionId, teacherId, subjectId } = req.body;
        
        const teacher = await User.findById(teacherId);
        if (!teacher) {
            return res.status(404).json({ message: 'Teacher not found' });
        }
        
        if (!teacher.specialty) {
            return res.status(400).json({ message: 'Teacher must be assigned a role (specialty) before being assigned to a subject.' });
        }

        if (!subjectId) {
            return res.status(400).json({ message: 'Subject is required when assigning a handled class.' });
        }

        const [section, subject] = await Promise.all([
            Section.findById(sectionId),
            Subject.findById(subjectId),
        ]);

        if (!section) return res.status(404).json({ message: 'Section not found' });
        if (!subject) return res.status(404).json({ message: 'Subject not found' });

        if (subject.category !== teacher.specialty) {
            return res.status(400).json({
                message: `${teacher.name} is a ${teacher.specialty} teacher and cannot be assigned to ${subject.category}.`
            });
        }

        const subjectAlreadyHandled = await User.findOne({
            _id: { $ne: teacher._id },
            handledClasses: {
                $elemMatch: {
                    section: sectionId,
                    subject: subjectId,
                }
            }
        });

        if (subjectAlreadyHandled) {
            return res.status(400).json({ message: `${subject.name} in ${section.name} is already assigned to another teacher.` });
        }

        const alreadyAssigned = teacher.handledClasses.some(hc => 
            hc.section &&
            hc.subject &&
            hc.section.toString() === sectionId &&
            hc.subject.toString() === subjectId
        );
        
        if (alreadyAssigned) {
            return res.status(400).json({ message: `${teacher.name} is already assigned to this subject and section.` });
        }

        teacher.handledClasses.push({ section: sectionId, subject: subjectId });
        teacher.subjects.addToSet(subjectId);
        await Promise.all([
            teacher.save(),
            Section.findByIdAndUpdate(sectionId, { $addToSet: { subjects: subjectId } })
        ]);
        
        const notif = await Notification.create({
            title: 'New Class Assignment',
            message: `You have been assigned to teach ${subject.name} in ${section.name}.`,
            target: 'SPECIFIC_USER',
            recipientId: teacher._id,
            type: 'system'
        });

        const populatedTeacher = await User.findById(teacher._id)
            .populate({
                path: 'handledClasses.section',
                select: 'name level students',
                populate: { path: 'level', select: 'name' }
            })
            .populate('handledClasses.subject', 'name code category');

        const io = req.app.get('io');
        if (io) {
            io.emit('new_notification', notif);
            io.emit('academic_updated', {
                action: 'handled_class_assigned',
                teacherId: teacher._id.toString(),
                sectionId,
                subjectId,
            });
        }

        res.json({
            message: 'Handled class assigned',
            handledClasses: populatedTeacher.handledClasses,
        });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.enrollStudentToSection = async (req, res) => {
    try {
        const { sectionId, studentId, studentIds } = req.body;
        
        // Support both single studentId or array of studentIds
        let idsToEnroll = [];
        if (studentIds && Array.isArray(studentIds)) {
            idsToEnroll = studentIds;
        } else if (studentId) {
            idsToEnroll = [studentId];
        }

        if (idsToEnroll.length === 0) {
            return res.status(400).json({ message: "No students provided" });
        }
        
        // Remove students from any previous section first
        await Section.updateMany(
            { students: { $in: idsToEnroll } },
            { $pull: { students: { $in: idsToEnroll } } }
        );

        const section = await Section.findByIdAndUpdate(
            sectionId,
            { $addToSet: { students: { $each: idsToEnroll } } },
            { new: true }
        ).populate('students', 'name email');

        // Also update user records
        await User.updateMany(
            { _id: { $in: idsToEnroll } }, 
            { section: sectionId }
        );

        const io = req.app.get('io');
        if (io) {
            io.emit('academic_updated', {
                action: 'students_enrolled',
                sectionId,
                studentIds: idsToEnroll,
            });
        }

        res.json(section);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.removeStudentFromSection = async (req, res) => {
    try {
        const { sectionId, studentId } = req.body;
        
        await Section.findByIdAndUpdate(
            sectionId,
            { $pull: { students: studentId } }
        );

        await User.findByIdAndUpdate(studentId, { $unset: { section: "" } });

        const io = req.app.get('io');
        if (io) {
            io.emit('academic_updated', {
                action: 'student_removed',
                sectionId,
                studentId,
            });
        }

        res.json({ message: "Student removed from section successfully" });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// --- Subject Controllers ---

exports.createSubject = async (req, res) => {
    try {
        const { sectionId, ...subjectData } = req.body;
        
        // Check if subject with this code already exists to prevent 11000 duplicate error
        let subject = await Subject.findOne({ code: subjectData.code });
        
        if (!subject) {
            subject = await Subject.create(subjectData);
        }
        
        if (sectionId) {
            await Section.findByIdAndUpdate(
                sectionId,
                { $addToSet: { subjects: subject._id } }
            );
        }

        const io = req.app.get('io');
        if (io) {
            io.emit('academic_updated', {
                action: 'subject_created',
                subjectId: subject._id.toString(),
                sectionId,
            });
        }
        
        res.status(201).json(subject);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.getSubjects = async (req, res) => {
    try {
        const subjects = await Subject.find();
        res.json(subjects);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.assignTeacherRole = async (req, res) => {
    try {
        const { teacherId } = req.params;
        const { specialty } = req.body; // e.g., 'Mathematics' or 'Science'

        const teacher = await User.findById(teacherId);
        if (!teacher) return res.status(404).json({ message: 'Teacher not found' });
        if (teacher.role !== 'teacher') return res.status(400).json({ message: 'User is not a teacher' });

        if (!['Mathematics', 'Science'].includes(specialty)) {
            return res.status(400).json({ message: 'Invalid specialty role' });
        }

        await teacher.populate('handledClasses.subject');
        teacher.specialty = specialty;
        teacher.handledClasses = teacher.handledClasses.filter(hc =>
            !hc.subject || hc.subject.category === specialty
        );
        await teacher.save();

        const notif = await Notification.create({
            title: 'Role Assigned',
            message: `You have been assigned as a ${specialty} teacher.`,
            target: 'SPECIFIC_USER',
            recipientId: teacher._id,
            type: 'system'
        });
        const io = req.app.get('io');
        if (io) {
            io.emit('new_notification', notif);
            io.emit('academic_updated', {
                action: 'teacher_role_assigned',
                teacherId: teacher._id.toString(),
                specialty,
            });
        }

        res.json({ message: `Teacher assigned as ${specialty} teacher`, teacher });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};
// --- User Fetching Controllers ---

exports.getTeachers = async (req, res) => {
    try {
        const teachers = await User.find({ role: 'teacher' })
            .select('-password');
        
        // Enhance with full handled classes info
        const teachersWithHandles = await Promise.all(teachers.map(async (teacher) => {
            const populatedTeacher = await User.findById(teacher._id)
                .populate({
                    path: 'handledClasses.section',
                    select: 'name level students',
                    populate: { path: 'level', select: 'name' }
                })
                .populate('handledClasses.subject', 'name code category');
            
            const activeHandledClasses = populatedTeacher.specialty
                ? populatedTeacher.handledClasses.filter(hc => !hc.subject || hc.subject.category === populatedTeacher.specialty)
                : populatedTeacher.handledClasses;

            let totalStudents = 0;
            // To keep backwards compatibility with the dashboard UI strings:
            const handles = activeHandledClasses.map(hc => {
                if (hc.section) {
                    if (hc.section.students) {
                        totalStudents += hc.section.students.length;
                    }
                    if (hc.section.level) {
                        return `${hc.section.level.name} - ${hc.section.name}`;
                    }
                }
                return 'Unknown Section';
            });

            return {
                ...populatedTeacher._doc,
                handles: handles,
                subjectRole: populatedTeacher.specialty,
                totalStudents: totalStudents,
                handledClasses: activeHandledClasses,
                handledClassesPopulated: activeHandledClasses.map(hc => ({
                    _id: hc._id,
                    section: hc.section ? {
                        _id: hc.section._id,
                        name: hc.section.name,
                        level: hc.section.level,
                        studentCount: hc.section.students ? hc.section.students.length : 0,
                        students: hc.section.students || [],
                    } : null,
                    subject: hc.subject ? {
                        _id: hc.subject._id,
                        name: hc.subject.name,
                        code: hc.subject.code,
                        category: hc.subject.category,
                    } : null,
                })),
            };
        }));

        res.json(teachersWithHandles);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getStudents = async (req, res) => {
    try {
        const students = await User.find({ role: 'student' })
            .populate({
                path: 'section',
                select: 'name level',
                populate: { path: 'level', select: 'name' }
            })
            .select('-password');
        res.json(students);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.approveUser = async (req, res) => {
    try {
        const { userId } = req.body;
        const user = await User.findById(userId);
        
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        user.isApproved = true;
        await user.save();

        const io = req.app.get('io');
        if (io) io.emit('academic_updated', { action: 'user_approved', userId: user._id.toString() });

        res.json({ message: "User approved successfully", user });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getStats = async (req, res) => {
    try {
        const studentCount = await User.countDocuments({ role: 'student' });
        const teacherCount = await User.countDocuments({ role: 'teacher' });
        const lessonCount = await require('../models/Lesson').countDocuments();
        
        res.json({
            studentCount,
            teacherCount,
            lessonCount
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Suspend/Unsuspend user
exports.suspendUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        user.isActive = !user.isActive;
        await user.save();

        // Also disable/enable in Firebase Auth
        if (user.firebaseUid) {
            if (admin.apps && admin.apps.length > 0) {
                try {
                    await admin.auth().updateUser(user.firebaseUid, { disabled: !user.isActive });
                    console.log(`Firebase Auth: User ${user.firebaseUid} ${user.isActive ? 'enabled' : 'disabled'}`);
                } catch (fbErr) {
                    console.error('Firebase suspend/unsuspend error:', fbErr.message);
                    return res.status(500).json({ message: 'Failed to update status in Firebase: ' + fbErr.message });
                }
            } else {
                console.warn("WARNING: Firebase Admin not initialized. Cannot update Firebase.");
                return res.status(500).json({ message: 'Firebase Admin not initialized on server. Status update aborted.' });
            }
        }

        const io = req.app.get('io');
        if (io) io.emit('academic_updated', { action: 'user_suspended_toggled', userId: user._id.toString(), isActive: user.isActive });
        
        res.json({ 
            message: user.isActive ? 'User reactivated' : 'User suspended', 
            isActive: user.isActive 
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Delete user
exports.deleteUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Delete from Firebase Auth if firebaseUid exists
        if (user.firebaseUid) {
            if (admin.apps && admin.apps.length > 0) {
                try {
                    await admin.auth().deleteUser(user.firebaseUid);
                    console.log(`Firebase Auth: Deleted user ${user.firebaseUid}`);
                } catch (fbErr) {
                    console.error('Firebase delete error:', fbErr.message);
                    if (fbErr.code !== 'auth/user-not-found') {
                        return res.status(500).json({ message: 'Failed to delete from Firebase: ' + fbErr.message });
                    }
                }
            } else {
                console.warn("WARNING: Firebase Admin not initialized. Cannot delete user from Firebase.");
                return res.status(500).json({ message: 'Firebase Admin not initialized on server. Deletion aborted.' });
            }
        }

        // Clean up: remove student from sections
        if (user.role === 'student') {
            await Section.updateMany(
                { students: userId },
                { $pull: { students: userId } }
            );
        }

        // Clean up: remove teacher handled classes references
        if (user.role === 'teacher') {
            // No section cleanup needed, handled classes are embedded in user doc
        }

        await User.findByIdAndDelete(userId);

        const io = req.app.get('io');
        if (io) io.emit('academic_updated', { action: 'user_deleted', userId });

        res.json({ message: 'User deleted from Database and Firebase' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update teacher profile (name/email)
exports.updateTeacherProfile = async (req, res) => {
    try {
        const { teacherId } = req.params;
        const { name, email } = req.body;

        const teacher = await User.findById(teacherId);
        if (!teacher) return res.status(404).json({ message: 'Teacher not found' });

        if (name) teacher.name = name;
        if (email) teacher.email = email;
        await teacher.save();

        const io = req.app.get('io');
        if (io) io.emit('academic_updated', { action: 'teacher_profile_updated', teacherId: teacher._id.toString() });

        res.json({ message: 'Profile updated', teacher });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Remove a handled class from teacher
exports.removeHandledClass = async (req, res) => {
    try {
        const { teacherId, handledClassId } = req.params;

        const teacher = await User.findById(teacherId);
        if (!teacher) return res.status(404).json({ message: 'Teacher not found' });

        teacher.handledClasses = teacher.handledClasses.filter(
            hc => hc._id.toString() !== handledClassId
        );
        await teacher.save();

        const io = req.app.get('io');
        if (io) {
            io.emit('academic_updated', {
                action: 'handled_class_removed',
                teacherId: teacher._id.toString(),
                handledClassId,
            });
        }

        res.json({ message: 'Handled class removed', teacher });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
