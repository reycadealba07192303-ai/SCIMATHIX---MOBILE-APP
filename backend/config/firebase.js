const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
// You will need to download your service account key from Firebase Console -> Project Settings -> Service Accounts -> Generate new private key
// and place it in the backend folder as 'firebaseServiceAccount.json'

const serviceAccountPath = path.join(__dirname, '..', 'firebaseServiceAccount.json');

if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin initialized successfully.');
} else {
    console.warn('WARNING: firebaseServiceAccount.json not found! Firebase Admin is NOT initialized. User deletion in Firebase will not work.');
}

module.exports = admin;
