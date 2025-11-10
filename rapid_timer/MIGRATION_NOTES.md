# Firebase Cross-Device Progression Setup

These steps configure Firebase so solves sync across devices using Firestore.

## 1. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Ensure `~/.pub-cache/bin` is on your PATH.

## 2. Create a Firebase Project

In the Firebase console create a new project (e.g. `rapid-timer`). Enable Firestore (Native mode) and Authentication (Anonymous sign-in).

## 3. Register Apps

Run:

```bash
flutterfire configure --project=<your-project-id> --platforms=android,ios,macos,web
```

This generates `lib/firebase_options.dart` replacing the stub. Commit the file.

If you also want Windows/Linux, add them after enabling desktop support:

```bash
flutterfire configure --platforms=windows,linux
```

## 4. Platform Files

Android: `google-services.json` auto added; ensure in `android/app/` and Gradle plugin lines added by FlutterFire.
iOS/macOS: `GoogleService-Info.plist` added under platform Runner targets.
Web: The CLI updates `web/index.html` with Firebase config.

## 5. Authentication

Enable Anonymous sign-in in Firebase console > Build > Authentication > Sign-in Method.

## 6. Firestore Rules (Basic)

In Firestore rules set (adjust later for hardened security):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/solves/{solveId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Publish rules.

## 7. Data Model

Collection: `users/{uid}/solves/{docId}` with fields:

- `time`: string (e.g. "00:12.34")
- `date`: ISO string (e.g. `2025-11-10T14:22:05.123Z`)
- `updatedAt`: server timestamp

DocId: base64Url(date|time) for stability.

## 8. Sync Behavior

Local writes queue immediately (optimistic). Remote snapshot merges only new solves to avoid duplicates. Deletes propagate instantly.

## 9. Offline

If Firebase fails to initialize (no config) the app still works locally; once config added and app restarted, initial merge occurs.

## 10. Testing

Run once after configuration:

```bash
flutter pub get
flutter run
```

Add a solve on one device/emulator; confirm it appears on another after snapshot refresh.

## 11. Future Hardening Ideas

- Conflict resolution based on `updatedAt`
- Analytics events for usage patterns
- Optional user account sign-in (email/google) to persist across reinstalls
