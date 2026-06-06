# Tech Stack

## Backend (Node.js / Express)

- **Runtime:** Node.js
- **Framework:** Express 5
- **Database:** MongoDB via Mongoose 9
- **Auth:** JWT (jsonwebtoken) + Firebase Admin SDK for Firebase UID linking
- **Real-time:** Socket.IO 4
- **File uploads:** Multer with Cloudinary storage
- **PDF parsing:** pdf-parse
- **AI:** External AI service (via axios calls)
- **Math:** mathjs for computation
- **Password hashing:** bcryptjs
- **Environment config:** dotenv

## Frontend (Flutter / Dart)

- **Framework:** Flutter (Dart SDK ^3.11.5)
- **State Management:** Riverpod (flutter_riverpod)
- **HTTP:** http package
- **Auth:** Firebase Auth + Firebase Core
- **Charts:** fl_chart
- **PDF generation:** pdf + printing packages
- **Animations:** animate_do, flutter_spinkit, lottie
- **Fonts:** google_fonts
- **File handling:** file_picker, image_picker, path_provider
- **Markdown rendering:** flutter_markdown
- **Real-time:** socket_io_client
- **Storage:** shared_preferences (local token/session persistence)

## Common Commands

### Backend
```bash
cd backend
npm install          # Install dependencies
npm run dev          # Start dev server with nodemon (hot reload)
npm start            # Start production server
```

### Frontend
```bash
cd frontend
flutter pub get      # Install dependencies
flutter run          # Run app (debug mode)
flutter build apk    # Build Android APK
flutter build web    # Build web version
```

## Environment Variables (backend/.env)
Required keys: `PORT`, `MONGO_URI`, `JWT_SECRET`, plus Cloudinary and Firebase config values. Do not commit secrets.
