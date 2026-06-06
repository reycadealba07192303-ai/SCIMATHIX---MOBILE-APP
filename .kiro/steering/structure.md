# Project Structure

Monorepo with two top-level directories: `backend/` (Node.js API) and `frontend/` (Flutter app).

## Backend (`backend/`)

```
backend/
├── index.js                 # Express app entry point, DB connection, Socket.IO setup
├── config/
│   ├── firebase.js          # Firebase Admin SDK initialization
│   └── generateToken.js     # JWT token generation helper
├── controllers/             # Route handler logic (one file per domain)
│   ├── auth_controller.js
│   ├── lesson_controller.js
│   ├── quiz_controller.js
│   └── ...
├── models/                  # Mongoose schemas (one file per collection)
│   ├── User.js
│   ├── Quiz.js
│   ├── Lesson.js
│   └── ...
├── routes/                  # Express route definitions (one file per domain)
│   ├── auth_routes.js
│   ├── quiz_routes.js
│   └── ...
├── middleware/
│   ├── auth_middleware.js   # JWT verification, role guards (protect, teacherOnly, adminOnly)
│   └── upload_middleware.js # Multer/Cloudinary file upload config
├── services/
│   ├── ai_service.js        # AI integration logic
│   └── cloudinary_service.js
├── utils/
│   ├── logger.js            # Activity log creation helper
│   └── randomizer.js
├── uploads/                 # Temporary local file uploads
├── seed.js                  # Database seeding script
└── package.json
```

### Backend conventions
- Controllers use `exports.functionName = async (req, res) => {}` pattern
- Route comments follow `@desc`, `@route`, `@access` JSDoc style
- Middleware chain: `protect` → role guard (`teacherOnly`/`adminOnly`) → controller
- Models export a single Mongoose model via `module.exports = mongoose.model(...)`
- Socket.IO instance accessed via `req.app.get('io')` in controllers

## Frontend (`frontend/lib/`)

```
frontend/lib/
├── main.dart                # App entry point, Firebase init, MaterialApp with routes
├── firebase_options.dart    # Auto-generated Firebase config
├── core/
│   ├── config/              # API base URL, app-wide configuration
│   ├── constants/           # Color constants, sizing, enums
│   └── theme/               # AppTheme definition (light theme)
├── data/
│   ├── models/              # Data classes / DTOs
│   └── services/            # HTTP API service classes
├── logic/                   # Riverpod providers (state management)
│   ├── auth_provider.dart
│   ├── data_providers.dart
│   └── admin_navigation_provider.dart
└── presentation/
    ├── root_wrapper.dart    # Role-based navigation after login
    ├── screens/
    │   ├── auth/            # Login, register, onboarding, splash
    │   ├── student/         # Student dashboard, lessons, quizzes, chat, AI, gamification
    │   ├── teacher/         # Teacher dashboard, classroom, analytics, lessons, quizzes
    │   └── admin/           # Admin dashboard, users, academic, reports, monitoring
    └── widgets/             # Reusable UI components
```

### Frontend conventions
- State management via Riverpod providers (not setState)
- Screens organized by user role (`student/`, `teacher/`, `admin/`)
- Data layer separated from presentation (services handle HTTP calls)
- Named routes defined in `main.dart`
- `const` constructors used where possible
