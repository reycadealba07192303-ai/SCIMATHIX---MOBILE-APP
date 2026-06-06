# Implementation Plan

## Overview

Implementation plan for the SCIMATHIX multi-feature enhancement. Tasks 1–18 cover the seven original feature enhancements (calendar/announcements, quiz workflow corrections, admin CRUD, teacher analytics, and notifications). Tasks 19–30 cover Round 2 bug fixes and enhancements discovered during live testing. All tasks are complete.

## Tasks

- [x] 1. Extend Announcement model with scheduling fields
  - Add `title` (String), `scheduledDate` (Date), and `scheduledTime` (String) fields to `backend/models/Announcement.js`
  - Keep existing `content` field for the description body
  - _Requirements: 1.1, 2.2_

- [x] 2. Update announcement controller to accept scheduling fields
  - Modify `createAnnouncement` in `backend/controllers/announcement_controller.js` to read `title`, `scheduledDate`, `scheduledTime` from `req.body` and persist them
  - Modify `updateAnnouncement` to accept and update the same fields
  - _Requirements: 1.1, 2.2_

- [x] 3. Add calendar feed API endpoint
  - Add `GET /api/announcements/calendar/:sectionId` route in `backend/routes/announcement_routes.js`
  - Implement controller handler that returns announcements for the section having `scheduledDate`, plus admin notifications of type `announcement` with embedded date info
  - Apply `protect` middleware
  - _Requirements: 1.2, 1.3_

- [x] 4. Quiz controller: skip recording teacher submissions
  - Modify `submitQuiz` in `backend/controllers/quiz_controller.js` to short-circuit before persisting `QuizAttempt` and incrementing XP when `req.user.role === 'teacher'`
  - Still compute and return score/results so the teacher sees feedback
  - Preserve existing student behaviour
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 5. Quiz deletion cascade
  - Modify `deleteQuiz` in `backend/controllers/quiz_controller.js` to call `await QuizAttempt.deleteMany({ quiz: quiz._id })` before deleting the quiz document
  - Surface errors so the quiz is not deleted if cascade fails
  - _Requirements: 4.1, 4.2_

- [x] 6. Admin announcement update/delete routes
  - Add `PUT /:id` and `DELETE /:id` routes in `backend/routes/notification_routes.js` (admin-only)
  - Implement the corresponding controller handlers (or extend existing notification controller) to update title/message/target and to delete by id
  - _Requirements: 5.3, 5.5_

- [x] 7. Teacher analytics endpoints
  - Add `getTeacherSectionPerformance`, `getTeacherWeakTopics`, and `getTeacherMonitoring` handlers in `backend/controllers/analytics_controller.js`
    - Section performance: per-section average score, pass rate, quiz count
    - Weak topics: aggregate of topics where teacher's students perform worst
    - Monitoring: recent activity, inactive students, completion rates
  - Register the three routes in `backend/routes/analytics_routes.js` with `protect` + `teacherOnly`
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 8. Flutter API service updates
  - In `frontend/lib/data/services/api_service.dart`:
    - Update `createAnnouncement()` to send `title`, `scheduledDate`, `scheduledTime`, `content`
    - Add `fetchCalendarAnnouncements(String sectionId)` for the new calendar endpoint
    - Add `deleteNotification(String id)` and `updateNotification(String id, {title, message, target})`
    - Add `fetchSectionPerformance()`, `fetchWeakTopics()`, `fetchMonitoring()` for the three teacher analytics endpoints
  - _Requirements: 1.3, 2.2, 5.3, 5.5, 6.1, 6.2, 6.3_

- [x] 9. Student calendar screen — dynamic data
  - Modify `frontend/lib/presentation/screens/student/student_calendar_screen.dart`
  - Replace hardcoded week with `DateTime.now()`-based week
  - Fetch from `fetchCalendarAnnouncements` and filter by selected date
  - Render title, time, subject tag, and description per event
  - Add empty state for dates without events
  - _Requirements: 1.3, 1.4, 1.6_

- [x] 10. Student dashboard "See All" navigation
  - Modify `frontend/lib/presentation/screens/student/student_dashboard.dart`
  - Wrap the "See All" label with `GestureDetector` (or `InkWell`) that switches the bottom-nav to the Classroom tab (index 1)
  - _Requirements: 1.5_

- [x] 11. Teacher classroom — enhanced create-post sheet
  - Modify `_showCreatePostDialog()` in `frontend/lib/presentation/screens/teacher/classroom/teacher_classroom_screen.dart`
  - Add Title field, Date picker, Time picker, read-only Section chip from `widget.handledClass.sectionId`, and multi-line Details field
  - Validate required fields before submit
  - Call updated `createAnnouncement` API with all fields
  - Update stream post card to render title, date/time, and details
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 12. Admin announcements full CRUD UI
  - Modify `frontend/lib/presentation/screens/admin/dashboard/admin_announcements_screen.dart`
  - Add `PopupMenuButton` (⋮) on each card with Edit and Delete entries
  - Edit dialog: pre-fill with current title/message/target, save calls `updateNotification`
  - Delete dialog: Cancel and Delete buttons placed side by side using `Row` with two `Expanded`; confirm calls `deleteNotification`
  - Refresh list after edit/delete
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 13. Teacher Section Performance screen
  - Create `frontend/lib/presentation/screens/teacher/analytics/teacher_section_performance_screen.dart`
  - Fetch from `fetchSectionPerformance()` and render per-section cards (avg score, pass rate, quiz count)
  - Include loading and empty states
  - _Requirements: 6.1, 6.4_

- [x] 14. Teacher Weak Topics screen
  - Create `frontend/lib/presentation/screens/teacher/analytics/teacher_weak_topics_screen.dart`
  - Fetch from `fetchWeakTopics()` and render a ranked list of weak topics with metric (e.g., avg score, attempt count)
  - Include loading and empty states
  - _Requirements: 6.2, 6.4_

- [x] 15. Teacher Monitoring screen
  - Create `frontend/lib/presentation/screens/teacher/analytics/teacher_monitoring_screen.dart`
  - Fetch from `fetchMonitoring()` and render recent activity, inactive student list, and completion-rate summary
  - Include loading and empty states
  - _Requirements: 6.3, 6.4_

- [x] 16. Wire teacher Quick Reports navigation
  - Modify `frontend/lib/presentation/screens/teacher/analytics/teacher_analytics_screen.dart`
  - Replace empty `onTap` callbacks on the three Quick Reports cards with `Navigator.push` to the three new screens
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 17. Student notifications — real data
  - Modify `frontend/lib/presentation/screens/student/student_notifications_screen.dart`
  - Convert to `StatefulWidget`
  - Fetch notifications scoped to `STUDENT ONLY` + `OVERALL`
  - Group by date (Today / Yesterday / Older) and mark as read on tap
  - Empty state when none
  - _Requirements: 7.1, 7.4, 7.5, 7.6_

- [x] 18. Teacher notifications — real data
  - Modify `frontend/lib/presentation/screens/teacher/teacher_notifications_screen.dart`
  - Convert to `StatefulWidget`
  - Fetch notifications scoped to `TEACHER ONLY` + `OVERALL`
  - Group by date and mark as read on tap
  - Empty state when none
  - _Requirements: 7.2, 7.4, 7.5, 7.6_

## Round 2 — Bug Fixes & Enhancements (Live Testing)

These tasks were discovered during live testing of the seven original enhancements. They continue the numbering from the plan above and are all complete. Items that extend an original requirement reference it; items that are new fixes are annotated as such.

- [x] 19. Teacher delete-announcement dialog — side-by-side buttons (R1)
  - Update the teacher classroom delete-announcement confirmation dialog in `frontend/lib/presentation/screens/teacher/classroom/teacher_classroom_screen.dart`
  - Place Cancel and Delete buttons in a single `Row` using two `Expanded`, matching the admin pattern
  - _Requirements: 5.4 (side-by-side button pattern applied to teacher dialog)_

- [x] 20. Student stream renders structured announcements (R2)
  - Update the student-facing classroom stream to render announcement `title`, `scheduledDate`/`scheduledTime`, and `content` details (not plain text)
  - Mirror the teacher stream card layout for consistency
  - _Requirements: 2.4, 1.4_

- [x] 21. Real-time sync of teacher announcement update/delete to students (R3)
  - Emit Socket.IO events from `backend/controllers/announcement_controller.js` on announcement update and delete so student clients refresh without reload
  - Add client-side socket listeners in the student stream/calendar to apply update/delete events live
  - _Requirements: 1.3, 2.2 (real-time delivery via Socket.IO per Architecture Notes)_

- [x] 22. Teacher lessons full CRUD from UI (R4)
  - Add edit and delete actions via a `PopupMenuButton` (⋮) on teacher lesson cards
  - Wire edit to the lesson update flow and delete to the lesson delete endpoint in `backend/controllers/lesson_controller.js`
  - Refresh the lesson list after edit/delete
  - _New enhancement (no original requirement); follows the CRUD/popup-menu pattern from Requirement 5_

- [x] 23. Quiz-to-lesson linkage and stale placeholder filtering (R5)
  - Ensure a quiz is associated with its source lesson in `backend/controllers/quiz_controller.js`
  - Filter out stale "analysis failed" placeholder content so it is not surfaced to students or in generated questions
  - _New fix related to the quiz workflow (Requirements 3, 4 area)_

- [x] 24. Student Classmates tab — real section data (R6)
  - Replace mock classmate data with real classmates fetched for the student's section
  - Add/extend the supporting API service call and render loading/empty states
  - _New enhancement (no original requirement)_

- [x] 25. AI chatbot conversation management (R7)
  - Add a "New Conversation" button and a conversation history list to the AI assistant screen
  - Back with `backend/controllers/chat_controller.js` / `Message` model so prior conversations can be listed and resumed
  - _New enhancement (no original requirement)_

- [x] 26. Teacher profile menu items functional (R8)
  - Wire the teacher profile menu entries — Edit Profile, My Sections, Lesson History, Notifications, App Settings, Help & Support — to their destinations/actions
  - _New enhancement; Notifications entry routes to the screen from Requirement 7.2_

- [x] 27. Profile image upload fix (R9)
  - Fix the teacher avatar empty-string guard so profile image upload works (avoid sending/persisting an empty image URL)
  - Verify upload path through `backend/middleware/upload_middleware.js` / `backend/services/cloudinary_service.js`
  - _New fix (no original requirement)_

- [x] 28. AI assistant reliability hardening (R10)
  - Add a request timeout, guarantee the loading spinner resets in all outcomes, and surface errors to the user in the AI flow (`backend/services/ai_service.js` + AI screen)
  - _New reliability fix (no original requirement)_

- [x] 29. Runtime error guards (R11a)
  - Add a 404 guard for missing `/uploads/` assets
  - Fix the ref-after-unmount error in the chat screen `dispose` lifecycle
  - _New fixes (no original requirement)_

- [x] 30. Weak Topics shows which students struggled per topic (R11b)
  - Extend `getTeacherWeakTopics` in `backend/controllers/analytics_controller.js` to include the struggling students per topic
  - Render the per-topic student breakdown in `frontend/lib/presentation/screens/teacher/analytics/teacher_weak_topics_screen.dart`
  - _Requirements: 6.2, 6.4 (extends Weak Topics with per-student detail)_

## Notes

- Tasks 1–18 cover the seven original feature enhancements; tasks 19–30 cover Round 2 bug fixes and enhancements found during live testing.
- Round 2 items map to the source file `round2-fixes.md` (R1–R11b).
- Requirement references are included where a Round 2 item extends or applies an existing requirement; items marked "new" are bug fixes/enhancements beyond the original seven requirements.
- All tasks are complete.

## Task Dependency Graph

All tasks (1–30) are complete. The waves below capture the dependency-ordered build sequence that was followed: backend models/controllers/routes first, then the Flutter API service, then the role screens, with same-file tasks kept in separate waves.

```json
{
  "waves": [
    { "id": 0, "tasks": ["1", "4", "6", "7"] },
    { "id": 1, "tasks": ["2", "5", "22", "25", "27", "28"] },
    { "id": 2, "tasks": ["3", "21", "23", "29"] },
    { "id": 3, "tasks": ["8"] },
    { "id": 4, "tasks": ["9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "20", "24", "26"] },
    { "id": 5, "tasks": ["19", "30"] }
  ]
}
```
