const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
// Supports both:
//   1. A local firebaseServiceAccount.json file (for local dev)
//   2. A FIREBASE_SERVICE_ACCOUNT env variable containing the JSON string (for Render/production)

// 1. Check if FIREBASE_SERVICE_ACCOUNT env var is set
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
        let serviceAccountStr = process.env.FIREBASE_SERVICE_ACCOUNT;
        // Sometimes env vars are wrapped in extra quotes, we can parse it first to unescape
        if (serviceAccountStr.startsWith('"') && serviceAccountStr.endsWith('"')) {
             serviceAccountStr = JSON.parse(serviceAccountStr);
        }
        const serviceAccount = typeof serviceAccountStr === 'string' ? JSON.parse(serviceAccountStr) : serviceAccountStr;
        
        // Handle private_key newlines just in case they are escaped as literal '\n'
        if (serviceAccount.private_key) {
             serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
        }

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('Firebase Admin initialized from environment variable.');
    } catch (err) {
        console.warn('WARNING: Failed to parse FIREBASE_SERVICE_ACCOUNT env variable:', err.message);
    }
}

// 2. Fallback to files if not already initialized
if (admin.apps.length === 0) {
    const localPath = path.join(__dirname, '..', 'firebaseServiceAccount.json');
    const secretPath = '/etc/secrets/firebaseServiceAccount.json'; // Render secret file path

    let certPathToUse = null;
    if (fs.existsSync(localPath)) {
        certPathToUse = localPath;
    } else if (fs.existsSync(secretPath)) {
        certPathToUse = secretPath;
    }

    if (certPathToUse) {
        try {
            const serviceAccount = require(certPathToUse);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
            console.log(`Firebase Admin initialized from file: ${certPathToUse}`);
        } catch (err) {
            console.error(`Failed to initialize Firebase from file ${certPathToUse}:`, err.message);
        }
    }
}

if (admin.apps.length === 0) {
    console.warn('WARNING: No Firebase credentials found! Firebase Admin is NOT initialized.');
}

module.exports = admin;
