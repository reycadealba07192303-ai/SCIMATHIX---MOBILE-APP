const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
// Supports both:
//   1. A local firebaseServiceAccount.json file (for local dev)
//   2. A FIREBASE_SERVICE_ACCOUNT env variable containing the JSON string (for Render/production)

const serviceAccountPath = path.join(__dirname, '..', 'firebaseServiceAccount.json');

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // Production: Load from environment variable
    try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin initialized from environment variable.');
    } catch (err) {
        console.warn('WARNING: Failed to parse FIREBASE_SERVICE_ACCOUNT env variable:', err.message);
    }
} else if (fs.existsSync(serviceAccountPath)) {
    // Local dev: Load from JSON file
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin initialized from local file.');
} else {
    console.warn('WARNING: No Firebase credentials found! Firebase Admin is NOT initialized.');
}

module.exports = admin;
