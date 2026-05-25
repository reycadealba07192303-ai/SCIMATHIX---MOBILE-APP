const Level = require('../models/Level');
const Section = require('../models/Section');
const Subject = require('../models/Subject');
const User = require('../models/User');

// --- Level Controllers ---

exports.createLevel = async (req, res) => {
    try {
        const level = await Level.create(req.body);
        res.status(201).json(level);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.getLevels = async (req, res) => {
    try {
        const levels = await Level.find().sort('order');
        res.json(levels);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// --- Section Controllers ---

exports.createSection = async (req, res) => {
    try {
        const section = await Section.create(req.body);
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
        const sections = await Section.find({ teacher: req.user._id })
            .populate('level', 'name')
            .populate('students', 'name email xp');
        res.json(sections);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getSectionDetails = async (req, res) => {
    try {
        const section = await Section.findById(req.params.sectionId)
            .populate('teacher', 'name email')
            .populate('students', 'name email')
            .populate('subjects');
        if (!section) return res.status(404).json({ message: 'Section not found' });
        res.json(section);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.assignTeacherToSection = async (req, res) => {
    try {
        const { sectionId, teacherId, subjectId } = req.body;
        
        // Add teacher to the section record
        const section = await Section.findByIdAndUpdate(
            sectionId,
            { teacher: teacherId },
            { new: true }
        ).populate('teacher', 'name email');

        // Add section and subject to teacher's handledClasses
        if (subjectId) {
            const teacher = await User.findById(teacherId);
            if (teacher) {
                // Check if already assigned
                const alreadyAssigned = teacher.handledClasses.some(hc => 
                    hc.section.toString() === sectionId && hc.subject.toString() === subjectId
                );
                
                if (!alreadyAssigned) {
                    teacher.handledClasses.push({ section: sectionId, subject: subjectId });
                    await teacher.save();
                }
            }
        }

        res.json(section);
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

        res.json({ message: "Student removed from section successfully" });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// --- Subject Controllers ---

exports.createSubject = async (req, res) => {
    try {
        const { sectionId, ...subjectData } = req.body;
        const subject = await Subject.create(subjectData);
        
        if (sectionId) {
            await Section.findByIdAndUpdate(
                sectionId,
                { $addToSet: { subjects: subject._id } }
            );
        }
        
        res.status(201).json(subject);
    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ message: "A teacher is already assigned to this subject for this section." });
        }
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

        teacher.specialty = specialty;
        await teacher.save();

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
            
            let totalStudents = 0;
            // To keep backwards compatibility with the dashboard UI strings:
            const handles = populatedTeacher.handledClasses.map(hc => {
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
                handledClassesPopulated: populatedTeacher.handledClasses.map(hc => ({
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
        const user = await User.findByIdAndDelete(userId);
        if (!user) return res.status(404).json({ message: 'User not found' });
        res.json({ message: 'User deleted successfully' });
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

        res.json({ message: 'Handled class removed', teacher });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
