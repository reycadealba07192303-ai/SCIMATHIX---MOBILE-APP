# SCIMATHIX Multi-Feature Enhancement Plan

This plan addresses 7 feature requests spanning backend and frontend changes across all 3 user roles (Student, Teacher, Admin).

---

## 1. Calendar – Real-Time Schedule from Announcements (Student)

**Problem**: The calendar screen is fully hardcoded with static mock data. It should show **real events from teacher and admin announcements** that have a scheduled date/time. The "See All" button on the dashboard also does nothing.

> [!IMPORTANT]
> The calendar is **fed by announcements** created by teachers (classroom-level) and admin (system-wide). When a teacher or admin creates an announcement with a date/time, it should appear on the student's calendar for the selected day.

### Backend

#### [MODIFY] [Announcement.js](file:///c:/Users/reyca/Downloads/SCIMATHIX/backend/models/Announcement.js)
- Add new fields: `title` (String), `scheduledDate` (Date), `scheduledTime` (String)
- Keep `content` for the details/description body

#### [MODIFY] [announcement_controller.js](file:///c:/Users/reyca/Downloads/SCIMATHIX/backend/controllers/announcement_controller.js) — `createAnnouncement`
- Accept new fields: `title`, `scheduledDate`, `scheduledTime` from req.body
- Store them in the Announcement document

#### [MODIFY] [announcement_controller.js](file:///c:/Users/reyca/Downloads/SCIMATHIX/backend/controllers/announcement_controller.js) — `updateAnnouncement`
- Also accept and update `title`, `scheduledDate`, `scheduledTime`

#### [NEW route] Add `GET /api/announcements/calendar/:sectionId` 
- Returns all announcements for the student's section that have a `scheduledDate`
- Also includes system-wide admin notifications (type=`announcement`) that have embedded date info
- This gives the calendar a single API to pull all scheduled events

### Frontend

#### [MODIFY] [student_calendar_screen.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/student/student_calendar_screen.dart)
- Replace hardcoded week/events with dynamic `DateTime.now()` based week
- Fetch scheduled announcements from the new calendar API
- Filter and display events matching the selected date
- Show title, time, subject tag, and description from announcement data

#### [MODIFY] [student_dashboard.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/student/student_dashboard.dart)
- Make "See All" on Recent Lessons a `GestureDetector` that switches to the Classroom tab (index 1)

---

## 2. Teacher Announcement – Enhanced Form with Title, Date, Time, Section, Details

**Problem**: The teacher announcement creation dialog currently only has a single text box. It needs proper fields: **Title, Date, Time, which section receives it, and Details**.

> [!IMPORTANT]
> The section is already known from the classroom context (`widget.handledClass.sectionId`), so it should be auto-filled but can display which section is receiving. The date and time fields will feed into the student calendar.

### Frontend

#### [MODIFY] [teacher_classroom_screen.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/teacher/classroom/teacher_classroom_screen.dart) — `_showCreatePostDialog()`
- Redesign the bottom sheet to include:
  - **Title** text field
  - **Date** picker (tap to select date)
  - **Time** picker (tap to select time)
  - **Section** display (auto-filled from the current class, shown as read-only chip)
  - **Details** multi-line text field (replaces the old single content box)
- Send all new fields to the backend `createAnnouncement` API

#### [MODIFY] [api_service.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/data/services/api_service.dart) — `createAnnouncement()`
- Update to accept and send `title`, `scheduledDate`, `scheduledTime` along with `content`

#### [MODIFY] Stream post display in teacher_classroom_screen.dart
- Show the title, date/time, and details in the stream card (not just plain `content`)

---

## 3. Teacher Quiz Testing – Don't Count Teacher's Answers

**Problem**: When a teacher tests their own quiz, their submission is stored and counted in analytics/leaderboard.

### Backend

#### [MODIFY] [quiz_controller.js](file:///c:/Users/reyca/Downloads/SCIMATHIX/backend/controllers/quiz_controller.js) — `submitQuiz`
- If `req.user.role === 'teacher'`: calculate and return the score/results, but **do NOT** create a `QuizAttempt` document and **do NOT** increment XP

---

## 4. Quiz Deletion Cascade – Remove from Students

**Problem**: When a teacher deletes a quiz, associated `QuizAttempt` records remain in the database.

### Backend

#### [MODIFY] [quiz_controller.js](file:///c:/Users/reyca/Downloads/SCIMATHIX/backend/controllers/quiz_controller.js) — `deleteQuiz`
- Add `await QuizAttempt.deleteMany({ quiz: quiz._id });` before deleting the quiz itself

---

## 5. Admin Announcements – Full CRUD

**Problem**: The admin announcements screen can create but cannot update or delete. Also, the delete dialog buttons are stacked — they should be **side by side**.

### Backend

#### [MODIFY] [notification_routes.js](file:///c:/Users/reyca/Downloads/SCIMATHIX/backend/routes/notification_routes.js)
- Add `DELETE /:id` route
- Add `PUT /:id` route to update title/message/target

### Frontend

#### [MODIFY] [api_service.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/data/services/api_service.dart)
- Add `deleteNotification(String id)` method
- Add `updateNotification(String id, {title, message, target})` method

#### [MODIFY] [admin_announcements_screen.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/admin/dashboard/admin_announcements_screen.dart)
- Add popup menu (⋮) on each card with **Edit** and **Delete** options
- Edit dialog pre-filled with current data
- Delete confirmation with **Cancel/Delete buttons side by side in one row** (using `Row` with two `Expanded`)

---

## 6. Teacher Quick Reports – Three Module Screens

**Problem**: Section Performance, Weak Topics, and Monitoring cards in Quick Reports have empty `onTap` callbacks.

### Backend

#### [MODIFY] [analytics_controller.js](file:///c:/Users/reyca/Downloads/SCIMATHIX/backend/controllers/analytics_controller.js)
- `getTeacherSectionPerformance` — per-section average scores, pass rates, quiz counts
- `getTeacherWeakTopics` — weak topics across all students in teacher's sections  
- `getTeacherMonitoring` — recent activity, inactive students, completion rates

#### [MODIFY] [analytics_routes.js](file:///c:/Users/reyca/Downloads/SCIMATHIX/backend/routes/analytics_routes.js)
- Add 3 new routes

#### [MODIFY] [api_service.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/data/services/api_service.dart)
- Add 3 new API methods

### Frontend

#### [NEW] [teacher_section_performance_screen.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/teacher/analytics/teacher_section_performance_screen.dart)
#### [NEW] [teacher_weak_topics_screen.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/teacher/analytics/teacher_weak_topics_screen.dart)
#### [NEW] [teacher_monitoring_screen.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/teacher/analytics/teacher_monitoring_screen.dart)

#### [MODIFY] [teacher_analytics_screen.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/teacher/analytics/teacher_analytics_screen.dart)
- Wire the three Quick Reports cards to navigate to their screens

---

## 7. Notifications – Functional for All 3 Roles

**Problem**: Student and Teacher notification screens show hardcoded mock data. Rules:
- **Students**: `STUDENT ONLY` + `OVERALL`
- **Teachers**: `TEACHER ONLY` + `OVERALL` (related to their classes)
- **Admin**: Full access to ALL

### Frontend

#### [MODIFY] [student_notifications_screen.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/student/student_notifications_screen.dart)
- Convert to `StatefulWidget`, fetch from API, group by date, mark as read on tap

#### [MODIFY] [teacher_notifications_screen.dart](file:///c:/Users/reyca/Downloads/SCIMATHIX/frontend/lib/presentation/screens/teacher/teacher_notifications_screen.dart)
- Convert to `StatefulWidget`, fetch from API, show real data, mark as read on tap

---

## Verification Plan

### Automated Tests
- Start backend with `npm run dev` and verify new API endpoints return correct data
- Run `flutter run` on web and verify no runtime errors

### Manual Verification
- Create teacher announcement with title/date/time → verify it appears on student calendar
- Create admin announcement → verify it appears on student calendar
- Teacher tests quiz → verify no QuizAttempt record created
- Teacher deletes quiz → verify student attempts also deleted
- Admin CRUD on announcements (create, edit, delete with side-by-side buttons)
- Quick Reports 3 modules navigate and show real data
- Notifications show real data for all 3 roles
