#!/usr/bin/env bash
# ============================================================================
# LYFSNEEDS 365+ - COMPLETE PRODUCTION DEPLOYMENT
# One-command setup: ./deploy.sh
# ============================================================================

set -euo pipefail

echo "🚀 LyfsNeeds 365+ - Production Deployment"
echo "=========================================="

# ============================================================================
# 1. PROJECT STRUCTURE INITIALIZATION
# ============================================================================

create_project_structure() {
    echo "📁 Creating project structure..."
    
    mkdir -p {
        app/src/{screens,components,services,utils,types,assets},
        backend/{functions,firestore,storage},
        web/public,
        docs,
        config,
        scripts,
        tests/{e2e,unit,integration},
        .github/workflows
    }
    
    echo "✓ Project structure created"
}

# ============================================================================
# 2. PACKAGE.JSON - REACT NATIVE + EXPO
# ============================================================================

cat > app/package.json <<'EOF'
{
  "name": "lyfsneeds-365",
  "version": "1.0.0",
  "main": "node_modules/expo/AppEntry.js",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web",
    "test": "jest",
    "lint": "eslint . --ext .js,.jsx,.ts,.tsx",
    "build:android": "eas build --platform android",
    "build:ios": "eas build --platform ios",
    "submit:android": "eas submit --platform android",
    "submit:ios": "eas submit --platform ios"
  },
  "dependencies": {
    "expo": "^50.0.0",
    "expo-location": "^16.5.0",
    "expo-notifications": "^0.27.0",
    "expo-camera": "^14.0.0",
    "expo-av": "^13.10.0",
    "react": "18.2.0",
    "react-native": "0.73.0",
    "react-native-maps": "1.10.0",
    "@react-navigation/native": "^6.1.9",
    "@react-navigation/stack": "^6.3.20",
    "@react-navigation/bottom-tabs": "^6.5.11",
    "firebase": "^10.7.1",
    "@react-native-firebase/app": "^19.0.0",
    "@react-native-firebase/auth": "^19.0.0",
    "@react-native-firebase/firestore": "^19.0.0",
    "@react-native-firebase/messaging": "^19.0.0",
    "@react-native-firebase/storage": "^19.0.0",
    "@stripe/stripe-react-native": "^0.35.0",
    "twilio-video": "^2.28.0",
    "react-native-webrtc": "^118.0.0",
    "libsodium-wrappers": "^0.7.13",
    "ngeohash": "^0.6.3",
    "axios": "^1.6.2",
    "date-fns": "^3.0.0",
    "react-native-reanimated": "^3.6.1",
    "react-native-gesture-handler": "^2.14.0",
    "react-native-safe-area-context": "^4.8.2",
    "react-native-screens": "^3.29.0",
    "@tensorflow/tfjs-react-native": "^0.8.0",
    "react-native-unity-view": "^2.1.0"
  },
  "devDependencies": {
    "@babel/core": "^7.23.6",
    "@types/react": "~18.2.45",
    "@types/react-native": "~0.73.0",
    "typescript": "^5.3.3",
    "jest": "^29.7.0",
    "@testing-library/react-native": "^12.4.0",
    "eslint": "^8.56.0",
    "prettier": "^3.1.1"
  }
}
EOF

# ============================================================================
# 3. APP.JSON - EXPO CONFIGURATION
# ============================================================================

cat > app/app.json <<'EOF'
{
  "expo": {
    "name": "LyfsNeeds 365+",
    "slug": "lyfsneeds-365",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#4F46E5"
    },
    "assetBundlePatterns": ["**/*"],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.lyfsneeds.app",
      "infoPlist": {
        "NSLocationWhenInUseUsageDescription": "LyfsNeeds needs your location to find nearby helpers and show your position during active gigs.",
        "NSLocationAlwaysAndWhenInUseUsageDescription": "LyfsNeeds needs background location to update your position during active gigs and provide safety features.",
        "NSCameraUsageDescription": "Camera is used for ID verification and video calls.",
        "NSMicrophoneUsageDescription": "Microphone is used for voice and video calls.",
        "NSPhotoLibraryUsageDescription": "Access photos to share images in chats.",
        "UIBackgroundModes": ["location", "fetch", "remote-notification", "voip"]
      },
      "associatedDomains": ["applinks:lyfsneeds.com"],
      "config": {
        "googleMapsApiKey": "YOUR_IOS_MAPS_KEY"
      }
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#4F46E5"
      },
      "package": "com.lyfsneeds.app",
      "permissions": [
        "ACCESS_FINE_LOCATION",
        "ACCESS_BACKGROUND_LOCATION",
        "CAMERA",
        "RECORD_AUDIO",
        "READ_EXTERNAL_STORAGE",
        "WRITE_EXTERNAL_STORAGE",
        "FOREGROUND_SERVICE"
      ],
      "config": {
        "googleMaps": {
          "apiKey": "YOUR_ANDROID_MAPS_KEY"
        }
      },
      "intentFilters": [
        {
          "action": "VIEW",
          "autoVerify": true,
          "data": [
            {
              "scheme": "https",
              "host": "lyfsneeds.com"
            }
          ],
          "category": ["BROWSABLE", "DEFAULT"]
        }
      ]
    },
    "web": {
      "favicon": "./assets/favicon.png"
    },
    "plugins": [
      "expo-location",
      "expo-camera",
      "expo-notifications",
      [
        "expo-build-properties",
        {
          "android": {
            "usesCleartextTraffic": false
          }
        }
      ]
    ],
    "extra": {
      "eas": {
        "projectId": "YOUR_EAS_PROJECT_ID"
      }
    }
  }
}
EOF

# ============================================================================
# 4. FIREBASE CONFIGURATION FILES
# ============================================================================

cat > backend/firestore/firestore.rules <<'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function hasVerifiedBadge() {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.verified == true;
    }
    
    function withinDistance(lat, lng, maxMeters) {
      let userLat = get(/databases/$(database)/documents/users/$(request.auth.uid)).data.location.latitude;
      let userLng = get(/databases/$(database)/documents/users/$(request.auth.uid)).data.location.longitude;
      let distance = sqrt(pow((lat - userLat) * 111320, 2) + pow((lng - userLng) * 85000, 2));
      return distance <= maxMeters;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false; // Never delete, only deactivate
      
      // Home location (private)
      match /home_geo/{doc} {
        allow read, write: if isOwner(userId);
      }
      
      // Location sharing (temporary)
      match /location/{doc} {
        allow read: if isOwner(userId) || 
                      (isSignedIn() && 
                       exists(/databases/$(database)/documents/location_access/$(userId + '_' + request.auth.uid)) &&
                       get(/databases/$(database)/documents/location_access/$(userId + '_' + request.auth.uid)).data.expiresAt > request.time);
        allow write: if isOwner(userId);
      }
    }
    
    // Gigs/Tasks
    match /gigs/{gigId} {
      allow read: if isSignedIn() && withinDistance(resource.data.location.latitude, resource.data.location.longitude, 50000);
      allow create: if isSignedIn() && hasVerifiedBadge();
      allow update: if isOwner(resource.data.userId) || 
                      (isSignedIn() && resource.data.responderId == request.auth.uid);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // Attention Alerts
    match /alerts/{alertId} {
      allow read: if isSignedIn() && withinDistance(resource.data.location.latitude, resource.data.location.longitude, 5000);
      allow create: if isSignedIn();
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // Location access grants (temp permissions)
    match /location_access/{accessId} {
      allow read: if isSignedIn() && 
                    (accessId.split('_')[0] == request.auth.uid || 
                     accessId.split('_')[1] == request.auth.uid);
      allow write: if false; // Only cloud functions can write
    }
    
    // Subscriptions
    match /subscriptions/{userId} {
      allow read: if isOwner(userId);
      allow write: if false; // Only cloud functions via Stripe webhooks
    }
    
    // Referral codes
    match /referrals/{code} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if false; // Only cloud functions
    }
    
    // Safety SOS events (write-only)
    match /sos_events/{eventId} {
      allow read: if false; // Only admins via Firebase Console
      allow create: if isSignedIn();
      allow update, delete: if false;
    }
    
    // Moderation queue
    match /moderation/{itemId} {
      allow read, write: if false; // Admin only via Firebase Console
    }
  }
}
EOF

cat > backend/firestore/firestore.indexes.json <<'EOF'
{
  "indexes": [
    {
      "collectionGroup": "gigs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "geohash", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "gigs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "geohash", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "alerts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "geohash", "order": "ASCENDING" },
        { "fieldPath": "active", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "verified", "order": "ASCENDING" },
        { "fieldPath": "rating", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
EOF

cat > backend/storage/storage.rules <<'EOF'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // User profile images
    match /profile_images/{userId}/{fileName} {
      allow read: if true; // Public
      allow write: if isOwner(userId) && 
                     request.resource.size < 5 * 1024 * 1024 && // 5MB max
                     request.resource.contentType.matches('image/.*');
    }
    
    // ID verification documents (encrypted)
    match /id_verification/{userId}/{fileName} {
      allow read: if false; // Admin only via console
      allow write: if isOwner(userId) && 
                     request.resource.size < 10 * 1024 * 1024; // 10MB max
    }
    
    // Call recordings (encrypted, 30-day auto-delete)
    match /call_recordings/{callId}/{fileName} {
      allow read: if false; // Admin only for legal/safety review
      allow write: if false; // Only cloud functions
    }
    
    // SOS audio clips (encrypted)
    match /sos_audio/{userId}/{eventId}.enc {
      allow read: if false; // Admin only
      allow write: if isOwner(userId);
    }
    
    // Media vault (Tier 3)
    match /media_vault/{userId}/{fileName} {
      allow read, write: if isOwner(userId) && 
                           request.resource.size < 50 * 1024 * 1024; // 50MB per file
    }
  }
}
EOF

# ============================================================================
# 5. CLOUD FUNCTIONS - BACKEND LOGIC
# ============================================================================

cat > backend/functions/package.json <<'EOF'
{
  "name": "lyfsneeds-functions",
  "version": "1.0.0",
  "engines": {
    "node": "18"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0",
    "stripe": "^14.10.0",
    "twilio": "^4.20.0",
    "axios": "^1.6.2",
    "ngeohash": "^0.6.3",
    "@google-cloud/translate": "^8.0.2",
    "node-schedule": "^2.1.1"
  },
  "devDependencies": {
    "typescript": "^5.3.3",
    "@types/node": "^20.10.6",
    "firebase-functions-test": "^3.1.1"
  },
  "scripts": {
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  }
}
EOF

cat > backend/functions/src/index.ts <<'TYPESCRIPT'
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import twilio from 'twilio';
import geohash from 'ngeohash';
import axios from 'axios';

admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage();

const stripe = new Stripe(functions.config().stripe.secret_key, {
  apiVersion: '2023-10-16'
});

const twilioClient = twilio(
  functions.config().twilio.account_sid,
  functions.config().twilio.auth_token
);

// ============================================================================
// 1. GEO SEARCH - NEARBY GIGS
// ============================================================================

export const getNearbyGigs = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const { lat, lng, query, radiusKm = 5 } = data;
  const maxRadius = 50;
  let currentRadius = radiusKm;
  let results: any[] = [];

  // Expand radius until we find results
  while (results.length < 3 && currentRadius <= maxRadius) {
    const geohashes = getGeohashesForRadius(lat, lng, currentRadius);
    
    const gigsSnapshot = await db.collection('gigs')
      .where('geohash', 'in', geohashes.slice(0, 10)) // Firestore limit
      .where('status', '==', 'open')
      .orderBy('createdAt', 'desc')
      .limit(20)
      .get();

    results = gigsSnapshot.docs
      .map(doc => ({
        id: doc.id,
        ...doc.data(),
        distance: calculateDistance(lat, lng, doc.data().location.latitude, doc.data().location.longitude)
      }))
      .filter(gig => {
        // Text search in title/description
        if (query) {
          const searchLower = query.toLowerCase();
          return gig.title.toLowerCase().includes(searchLower) ||
                 gig.description.toLowerCase().includes(searchLower);
        }
        return true;
      })
      .sort((a, b) => a.distance - b.distance);

    if (results.length < 3) {
      currentRadius *= 2;
    }
  }

  return { gigs: results, searchRadius: currentRadius };
});

function getGeohashesForRadius(lat: number, lng: number, radiusKm: number): string[] {
  const precision = radiusKm < 1 ? 7 : radiusKm < 5 ? 6 : radiusKm < 20 ? 5 : 4;
  const centerHash = geohash.encode(lat, lng, precision);
  const neighbors = geohash.neighbors(centerHash);
  return [centerHash, ...Object.values(neighbors)];
}

function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

// ============================================================================
// 2. ATTENTION ALERTS - CREATE & NOTIFY
// ============================================================================

export const createAttentionAlert = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const { title, description, lat, lng } = data;

  // Moderate content
  const toxicityScore = await moderateText(title + ' ' + description);
  if (toxicityScore > 0.7) {
    throw new functions.https.HttpsError('invalid-argument', 'Content flagged for review');
  }

  const alertDoc = await db.collection('alerts').add({
    userId: context.auth.uid,
    title,
    description,
    location: new admin.firestore.GeoPoint(lat, lng),
    geohash: geohash.encode(lat, lng, 6),
    active: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    responses: []
  });

  // Notify nearby users
  await notifyNearbyUsers(lat, lng, 5, {
    title: '🆘 Help Needed Nearby',
    body: `${title} - ${calculateDistance(lat, lng, lat, lng).toFixed(1)} mi away`,
    data: { alertId: alertDoc.id, type: 'alert' }
  });

  return { alertId: alertDoc.id };
});

async function notifyNearbyUsers(lat: number, lng: number, radiusKm: number, notification: any) {
  const geohashes = getGeohashesForRadius(lat, lng, radiusKm);
  
  const usersSnapshot = await db.collection('users')
    .where('geohash', 'in', geohashes.slice(0, 10))
    .where('notificationsEnabled', '==', true)
    .get();

  const tokens = usersSnapshot.docs
    .map(doc => doc.data().fcmToken)
    .filter(token => token);

  if (tokens.length > 0) {
    await admin.messaging().sendMulticast({
      tokens,
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: notification.data
    });
  }
}

async function moderateText(text: string): Promise<number> {
  try {
    const response = await axios.post(
      'https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze',
      {
        comment: { text },
        languages: ['en'],
        requestedAttributes: { TOXICITY: {} }
      },
      {
        params: { key: functions.config().google.perspective_api_key }
      }
    );
    return response.data.attributeScores.TOXICITY.summaryScore.value;
  } catch (error) {
    console.error('Moderation API error:', error);
    return 0; // Fail open
  }
}

// ============================================================================
// 3. TWILIO - VOICE/VIDEO CALL INITIATION
// ============================================================================

export const initiateCall = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }

  const { recipientUid, type } = data; // type: 'voice' | 'video'

  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  const recipientDoc = await db.collection('users').doc(recipientUid).get();

  if (!recipientDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Recipient not found');
  }

  // Create Twilio room for video or voice call
  const room = await twilioClient.video.v1.rooms.create({
    uniqueName: `call_${context.auth.uid}_${recipientUid}_${Date.now()}`,
    type: type === 'video' ? 'group' : 'peer-to-peer',
    recordParticipantsOnConnect: true, // For safety
    maxParticipants: 2
  });

  
