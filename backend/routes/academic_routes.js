const express = require('express');
const router = express.Router();
const { protect, adminOnly } = require('../middleware/auth_middleware');
const {
    createLevel, getLevels,
    createSection, getSectionsByLevel, getSectionDetails, assignTeacherToSection, enrollStudentToSection, removeStudentFromSection, getMySections,
    createSubject, getSubjects, assignTeacherRole,
    getTeachers, getStudents, getStats, approveUser,
    suspendUser, deleteUser, updateTeacherProfile, removeHandledClass
} = require('../controllers/academic_controller');

// Stats
router.get('/stats', getStats);

// Approval
router.post('/approve-user', protect, adminOnly, approveUser);

// Users
router.get('/teachers', getTeachers);
router.get('/students', getStudents);
router.put('/teachers/:teacherId/assign-role', assignTeacherRole);
router.put('/teachers/:teacherId/profile', updateTeacherProfile);
router.delete('/teachers/:teacherId/handled-classes/:handledClassId', removeHandledClass);

// Account management
router.put('/users/:userId/suspend', suspendUser);
router.delete('/users/:userId', deleteUser);

// Levels
router.post('/levels', createLevel);
router.get('/levels', getLevels);

// Sections
router.post('/sections', createSection);
router.get('/sections/my-sections', protect, getMySections); // Added for Teacher Dashboard
router.get('/sections/:levelId', getSectionsByLevel);
router.get('/sections/details/:sectionId', getSectionDetails);
router.post('/sections/assign-teacher', assignTeacherToSection);
router.post('/sections/enroll-student', enrollStudentToSection);
router.post('/sections/remove-student', removeStudentFromSection);

// Subjects
router.post('/subjects', createSubject);
router.get('/subjects', getSubjects);

module.exports = router;
