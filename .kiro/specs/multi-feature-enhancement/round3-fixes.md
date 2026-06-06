# Round 3 — UI Polish & New Features

- [x] T1. Delete Account popup (Teacher Management): Cancel/Delete buttons side by side, clean layout
- [x] T2. Student home: Upcoming Quizzes tappable + show scheduled/post date
- [x] T3. Change Password → email-based reset (Firebase reset email)
- [x] T4. Dark Mode: theme provider + persistence + dark theme; toggles wired in student settings + admin profile
- [x] T5. Student home: Recent Lessons cards tappable → LessonDetailsScreen
- [x] T6. Student Leaderboard: All Time / Weekly / Monthly tabs (backend period filter + UI)
- [x] T7. Student profile: Achievements, Activity History, Learning Statistics (real data via /analytics/student/stats)
- [x] T8. Settings General / Privacy / About sections functional
- [x] T9. Admin activity chart: fixed bottom overflow
- [x] T10. Profile picture upload (admin real upload via shared endpoint)

## Notes
- Dark mode infrastructure is global (MaterialApp.darkTheme + ThemeMode provider with persistence). Screens that hardcode AppTheme.backgroundColor/textColor still render light-styled surfaces; settings/change-password/stats screens were built theme-aware. A full per-screen dark migration across all ~40 screens is a follow-up.
