# Requirements Document

## Introduction

Seven feature enhancements covering calendar/announcements, quiz workflow corrections, admin CRUD, teacher analytics, and notifications across all three user roles of the SCIMATHIX learning management system.

## Glossary

- **System**: The SCIMATHIX learning management system (backend Node.js/Express API and Flutter frontend taken together).
- **Student**: A user with role `student` who consumes lessons, takes quizzes, and views announcements/notifications.
- **Teacher**: A user with role `teacher` who authors lessons/quizzes, manages sections, and views analytics.
- **Admin**: A user with role `admin` who manages users, academic settings, and system-wide announcements.
- **Section**: A class grouping that students belong to and that announcements can be targeted at.
- **Announcement**: A scheduled or immediate message authored by a teacher or admin, with optional `title`, `scheduledDate`, `scheduledTime`, `content`, and `sectionId` fields.
- **Calendar**: The student-facing screen that displays scheduled Announcements as date-keyed events.
- **Quiz**: A teacher-authored assessment composed of questions; students submit answers to produce attempts.
- **QuizAttempt**: A document stored in the database representing a single student's submission of a Quiz, used for analytics and leaderboard data.
- **XP**: Experience points awarded to students for activities such as submitting quizzes; used for gamification.
- **Notification**: A targeted message delivered to users based on role scope.
- **OVERALL**: A Notification scope value targeting all roles (students, teachers, admins).
- **STUDENT ONLY**: A Notification scope value targeting users with role `student`.
- **TEACHER ONLY**: A Notification scope value targeting users with role `teacher`.
- **Quick Reports**: The teacher dashboard area exposing Section Performance, Weak Topics, and Monitoring modules.
- **Section Performance**: An analytics view of per-section average scores, pass rates, and quiz counts.
- **Weak Topics**: An analytics view aggregating low-performing topics across students in a teacher's sections.
- **Monitoring**: An analytics view of recent activity, inactive students, and completion rates.

## Requirements

### Requirement 1: Real-Time Student Calendar from Announcements

**User Story:** As a student, I want my calendar to display real scheduled announcements from teachers and admins, so that I can keep track of upcoming classroom and school-wide events.

#### Acceptance Criteria

1. WHEN a teacher creates an announcement with a date and time THEN the system SHALL store `title`, `scheduledDate`, and `scheduledTime` on the Announcement document.
2. WHEN an admin creates an announcement with a date and time THEN the system SHALL include it in the calendar feed for relevant students.
3. WHEN a student opens the calendar screen THEN the system SHALL fetch scheduled events for their section via `GET /api/announcements/calendar/:sectionId`.
4. WHEN the student selects a date THEN the calendar SHALL display events whose `scheduledDate` matches that date with title, time, and description.
5. WHEN the student taps "See All" on the dashboard Recent Lessons section THEN the app SHALL navigate to the Classroom tab (index 1).
6. WHEN no events exist for a selected date THEN the calendar SHALL display an empty state.

### Requirement 2: Enhanced Teacher Announcement Form

**User Story:** As a teacher, I want to create announcements with title, scheduled date/time, target section, and details, so that students see structured events on their calendars.

#### Acceptance Criteria

1. WHEN a teacher opens the create-post bottom sheet THEN the form SHALL include Title, Date picker, Time picker, Section display (read-only), and Details fields.
2. WHEN the teacher submits the form THEN the API SHALL receive `title`, `scheduledDate`, `scheduledTime`, `content`, and `sectionId`.
3. WHEN required fields are missing THEN the form SHALL prevent submission and display validation feedback.
4. WHEN an announcement is displayed in the stream THEN the card SHALL render title, date/time, and details (not just plain content).

### Requirement 3: Teacher Quiz Test Submissions Excluded from Records

**User Story:** As a teacher, I want to test my own quizzes without polluting analytics or leaderboard data, so that real student performance metrics remain accurate.

#### Acceptance Criteria

1. WHEN a user with role `teacher` submits a quiz THEN the system SHALL calculate the score and return it.
2. WHEN a user with role `teacher` submits a quiz THEN the system SHALL NOT create a `QuizAttempt` document.
3. WHEN a user with role `teacher` submits a quiz THEN the system SHALL NOT increment user XP.
4. WHEN a user with role `student` submits a quiz THEN existing behaviour SHALL be preserved (attempt recorded, XP incremented).

### Requirement 4: Quiz Deletion Cascades to Attempts

**User Story:** As a teacher, I want deleting a quiz to also remove all student attempts of that quiz, so that orphaned records do not pollute the database.

#### Acceptance Criteria

1. WHEN a teacher deletes a quiz THEN the system SHALL delete all `QuizAttempt` documents where `quiz` matches the deleted quiz id before removing the quiz.
2. WHEN the cascade deletion fails THEN the system SHALL surface an error and not delete the quiz.

### Requirement 5: Admin Announcements Full CRUD

**User Story:** As an admin, I want to edit and delete announcements with a clean confirmation UI, so that I can manage announcements after creation.

#### Acceptance Criteria

1. WHEN an admin views the announcements list THEN each card SHALL show a popup menu with Edit and Delete actions.
2. WHEN the admin chooses Edit THEN a dialog SHALL pre-fill with the announcement's existing title, message, and target.
3. WHEN the admin saves an edit THEN the system SHALL call `PUT /api/notifications/:id` and update the document.
4. WHEN the admin chooses Delete THEN a confirmation dialog SHALL display Cancel and Delete buttons side by side using `Row` with two `Expanded`.
5. WHEN the admin confirms Delete THEN the system SHALL call `DELETE /api/notifications/:id` and remove the announcement from the list.

### Requirement 6: Teacher Quick Reports – Three Modules

**User Story:** As a teacher, I want to access Section Performance, Weak Topics, and Monitoring screens from Quick Reports, so that I can analyze student performance from one place.

#### Acceptance Criteria

1. WHEN a teacher taps the Section Performance card THEN the app SHALL navigate to a screen showing per-section average scores, pass rates, and quiz counts via a new analytics endpoint.
2. WHEN a teacher taps the Weak Topics card THEN the app SHALL navigate to a screen showing weak topics aggregated across all students in the teacher's sections.
3. WHEN a teacher taps the Monitoring card THEN the app SHALL navigate to a screen showing recent activity, inactive students, and completion rates.
4. WHEN any of the three endpoints return data THEN the screens SHALL render results cleanly with loading and empty states.

### Requirement 7: Functional Notifications for All Roles

**User Story:** As a user (student/teacher/admin), I want my notifications screen to show real notifications scoped to my role, so that I see only relevant updates.

#### Acceptance Criteria

1. WHEN a student opens the notifications screen THEN the system SHALL fetch notifications targeting `STUDENT ONLY` and `OVERALL`.
2. WHEN a teacher opens the notifications screen THEN the system SHALL fetch notifications targeting `TEACHER ONLY` and `OVERALL`.
3. WHEN an admin opens the notifications screen THEN the system SHALL fetch all notifications.
4. WHEN notifications are displayed THEN they SHALL be grouped by date (Today, Yesterday, Older).
5. WHEN a user taps a notification THEN it SHALL be marked as read.
6. WHEN no notifications exist THEN the screen SHALL display an empty state.
