# SCIMATHIX — Task Checklist

## ✅ Done

- [x] Backend running on port 5000, MongoDB connected
- [x] Firebase Admin SDK initialized
- [x] Frontend `ApiConfig` IP updated to current LAN IP (`192.168.234.168`)
- [x] JWT_SECRET updated from placeholder to real value
- [x] All backend routes verified — match frontend API calls
- [x] Flutter analyze passed (no compile errors)
- [x] Steering files created (product.md, tech.md, structure.md)
- [x] Full integration test completed (36 endpoints all passing)
- [x] Leaderboard fixed — now shows XP based on quiz scores + quiz title
- [x] **Fix placeholder quiz detection** — students no longer see quizzes with placeholder questions
- [x] **Announcement subjectId validation** — now optional (general announcements allowed)
- [x] **Removed unused DEEPSEEK_API_KEY** from `.env`
- [x] **Added `.env.example`** for other devs
- [x] **Added auth protection to all academic routes** — no more unauthenticated access
- [x] **Frontend academic calls updated** — all now send auth token
- [x] **Removed duplicate profile picture route** — only `PUT /api/users/profile-image` remains
- [x] **Fixed deprecated `withOpacity`** in `app_theme.dart`
- [x] **Added HTTP timeout** (30s) + 401 auto-clear token helper to ApiService
- [x] **Socket.IO reconnection logic** — auto-reconnect with backoff (10 attempts, 2-10s delay)
- [x] **Created root `.gitignore`** — excludes `.env`, `firebaseServiceAccount.json`, `node_modules`, uploads

---

## 🔧 Remaining (Low Priority)

- [ ] **Clean up ~35 unused imports** across frontend screens (cosmetic only)
- [ ] **Replace `print()` with proper logger** in ApiService for production
- [ ] **Fix null-aware operator warnings** in profile/classroom screens (cosmetic)
- [ ] **Remove unused fields** (`_teacher`, `_isChecking`, `_selectedRole`, etc.)
- [ ] **Configure Cloudinary** — add keys to `.env` when ready for cloud file storage
- [ ] **CORS lockdown** — change `origin: "*"` to allowed origins before deploy
- [ ] **HTTPS for production**

---

## 🚀 Nice to Have (Future)

- [ ] Unit tests (backend controllers, frontend providers)
- [ ] API rate limiting (express-rate-limit)
- [ ] Input sanitization (express-validator/joi)
- [ ] Refresh token flow (currently 30-day expiry with no refresh)
- [ ] Pagination on list endpoints
- [ ] Push notifications (FCM)
- [ ] Offline support / caching
- [ ] Dark mode

---

## 📝 Notes

- Backend JWT tokens expire in 30 days
- Gemini API (`gemini-2.5-flash`) handles lesson analysis + quiz generation
- If Gemini fails, content-based fallback generates questions from lesson text
- Firebase Auth is primary auth; backend JWT is secondary API auth
- Socket.IO handles real-time classroom updates and notifications
- Current LAN IP: `192.168.234.168` (use `--dart-define=API_HOST=<ip>` when it changes)
- Leaderboard ranks by category XP (score * 10), includes quiz title and stats
