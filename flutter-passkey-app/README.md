# Flutter Passkey Auth (Android + iOS)

This is a full sample that wires a Flutter UI to:
- **Android Credential Manager** (Google Password Manager + biometrics)
- **iOS AuthenticationServices** (Face ID / Touch ID)
- **Node.js WebAuthn backend** (`@simplewebauthn/server`) for challenge generation and verification

## 1) Run backend

```bash
cd backend-passkey
npm install
npm start
```

Server starts at `http://localhost:3000`.

## 2) Run Flutter app

```bash
cd flutter-passkey-app
flutter pub get
flutter run
```

### Android notes

- App uses `http://10.0.2.2:3000` by default for emulator.
- Add Credential Manager dependencies in `android/app/build.gradle` if your generated app does not include them:

```gradle
dependencies {
    implementation "androidx.credentials:credentials:1.3.0"
    implementation "androidx.credentials:credentials-play-services-auth:1.3.0"
}
```

### iOS notes

- Set deployment target to **iOS 16+**.
- Add Associated Domains entitlement for production passkeys (`webcredentials:<your-domain>`).
- Replace hardcoded RP ID/origin (`localhost`) with your real domain in backend and iOS provider.

## 3) Production checklist

1. Use HTTPS domain (no localhost) and a valid RP ID.
2. Host `apple-app-site-association` and `assetlinks.json`.
3. Persist users/credentials in database.
4. Add JWT/session issuance after login verification.
5. Validate request/response schemas and add rate limits.

## Project structure

- `flutter-passkey-app/lib/main.dart` — Flutter UI + API calls + method channel.
- `flutter-passkey-app/android/.../MainActivity.kt` — Android passkey create/get.
- `flutter-passkey-app/ios/Runner/AppDelegate.swift` — iOS passkey create/get.
- `backend-passkey/server.js` — WebAuthn register/login options + verify endpoints.
