## Design: SCIMATHIX Multi-Feature Enhancement

## Overview

Seven feature enhancements spanning backend (Node.js/Express) and frontend (Flutter/Dart) across all 3 user roles.

---

## Feature 1: Calendar – Real-Time Schedule from Announcements (Student)

### Problem
The student calendar screen is fully hardcoded with static mock data. The "See All" button on the dashboard does nothing.

### Solution
- Extend Announcement model with `title`, `scheduledDate`, `scheduledTime` fields
- Add new API endpoint `GET /api/announcements/calendar/:sectionId` to fetch scheduled events
- Replace hardcoded calendar UI with dynamic data from the API
- Wire "See All" button on dashboard to navigate to Classroom tab

### Data Flow
```
Teacher/Admin creates announcement with date → stored in DB → Student calendar API fetches by section + date → Calendar UI renders events
```

---

## Feature 2: Teacher Announcement – Enhanced Form

### Problem
The teacher announcement creation dialog only has a single text box.

### Solution
- Redesign bottom sheet with: Title, Date picker, Time picker, Section display (auto-filled), Details multi-line field
- Update API service to send all new fields
- Update stream post display to show structured announcement data

---

## Feature 3: Teacher Quiz Testing – Don't Count Teacher's Answers

### Problem
When a teacher tests their own quiz, their submission is stored and counted in analytics/leaderboard.

### Solution
- In `submitQuiz` controller: if `req.user.role === 'teacher'`, calculate and return score but do NOT create QuizAttempt or increment XP

---

## Feature 4: Quiz Deletion Cascade

### Problem
When a teacher deletes a quiz, associated QuizAttempt records remain orphaned.

### Solution
- In `deleteQuiz` controller: add `QuizAttempt.deleteMany({ quiz: quiz._id })` before deleting the quiz

---

## Feature 5: Admin Announcements – Full CRUD

### Problem
Admin can create but cannot update or delete announcements. Delete dialog buttons are stacked vertically.

### Solution
- Add `DELETE /:id` and `PUT /:id` routes to notification_routes
- Add corresponding API methods in Flutter
- Add popup menu (⋮) on each card with Edit/Delete options
- Delete confirmation dialog with side-by-side buttons (Row with two Expanded)

---

## Feature 6: Teacher Quick Reports – Three Module Screens

### Problem
Section Performance, Weak Topics, and Monitoring cards in Quick Reports have empty onTap callbacks.

### Solution
- Add 3 new analytics endpoints: section performance, weak topics, monitoring
- Create 3 new Flutter screens for each module
- Wire Quick Reports cards to navigate to new screens

### Endpoints
- `GET /api/analytics/teacher/section-performance` — per-section average scores, pass rates
- `GET /api/analytics/teacher/weak-topics` — weak topics across all students
- `GET /api/analytics/teacher/monitoring` — recent activity, inactive students

---

## Feature 7: Notifications – Functional for All 3 Roles

### Problem
Student and Teacher notification screens show hardcoded mock data.

### Solution
- Students see: `STUDENT ONLY` + `OVERALL` notifications
- Teachers see: `TEACHER ONLY` + `OVERALL` notifications
- Admin sees: ALL notifications
- Convert screens to StatefulWidget, fetch from API, group by date, mark as read on tap

---

## Architecture Notes

- All new backend routes follow existing middleware pattern: `protect` → role guard → controller
- Frontend follows Riverpod state management pattern
- Socket.IO used for real-time updates where applicable
- Existing API service pattern extended (no new service files needed)
