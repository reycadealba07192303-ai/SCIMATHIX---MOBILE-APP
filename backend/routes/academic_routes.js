const express = require('express');
const router = express.Router();
const { protect, adminOnly } = require('../middleware/auth_middleware');
const {
    createLevel, getLevels,
    createSection, getSectionsByLevel, getSectionDetails, assignTeacherToSection, enrollStudentToSection, removeStudentFromSection, getMySections,
    createSubject, getSubjects, assignTeacherRole,
    getTeachers, getStudents, getStats, approveUser,
    suspendUser, deleteUser, updateTeacherProfile, removeHandledClass,
    createSchoolYear, getSchoolYears
} = require('../controllers/academic_controller');

// Stats
router.get('/stats', protect, getStats);

// Approval
router.post('/approve-user', protect, adminOnly, approveUser);

// Users
router.get('/teachers', protect, getTeachers);
router.get('/students', protect, getStudents);
router.put('/teachers/:teacherId/assign-role', protect, adminOnly, assignTeacherRole);
router.put('/teachers/:teacherId/profile', protect, adminOnly, updateTeacherProfile);
router.delete('/teachers/:teacherId/handled-classes/:handledClassId', protect, adminOnly, removeHandledClass);

// Account management
router.put('/users/:userId/suspend', protect, adminOnly, suspendUser);
router.delete('/users/:userId', protect, adminOnly, deleteUser);

// School Years
router.post('/school-years', protect, adminOnly, createSchoolYear);
router.get('/school-years', protect, getSchoolYears);

// Levels
router.post('/levels', protect, adminOnly, createLevel);
router.get('/levels', protect, getLevels);

// Sections
router.post('/sections', protect, adminOnly, createSection);
router.get('/sections/my-sections', protect, getMySections);
router.get('/sections/:levelId', protect, getSectionsByLevel);
router.get('/sections/details/:sectionId', protect, getSectionDetails);
router.post('/sections/assign-teacher', protect, adminOnly, assignTeacherToSection);
router.post('/sections/enroll-student', protect, adminOnly, enrollStudentToSection);
router.post('/sections/remove-student', protect, adminOnly, removeStudentFromSection);

// Subjects
router.post('/subjects', protect, adminOnly, createSubject);
router.get('/subjects', protect, getSubjects);

module.exports = router;
