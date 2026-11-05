# In-Class Activity 13: Firebase Authentication

A Flutter Android app for CSC 4360. It supports email/password registration,
sign-in, sign-out, a protected profile showing the signed-in email, and password
changes.

## Features

- Firebase initializes before the app opens.
- `AuthService` owns the Firebase account operations and a stable
  `authStateChanges()` stream.
- Auth state selects the sign-in form or profile. Signing out removes the profile
  from the interface, including when Back is pressed.
- Registration checks email format, the six-character assignment minimum and
  password confirmation. Firebase also enforces its project password policy.
- Requests show loading feedback and disable repeated submissions.
- Sign-in failures use safe messages without revealing whether an email exists.
- Password changes handle `requires-recent-login` by asking for the current
  password, reauthenticating and retrying the update.
- Firebase restores the signed-in session when the Android app is reopened.

This activity uses Firebase Authentication. The optional Firestore extension is
not included. Protecting the profile UI does not replace database security rules.

## Prerequisites

- Flutter and Dart; verified with Flutter 3.47.3 and Dart 3.13.3.
- Android Studio/Android SDK, a compatible Java runtime, and an Android device or
  emulator. The app targets Android 7/API 24 or newer.
- Firebase CLI and FlutterFire CLI if configuring a different Firebase project.

The lockfile pins `firebase_core` 5.1.0 and `firebase_auth` 7.0.1.

## Firebase setup

Android client configuration is included for the dedicated class project
`ica13-campus-access-blake`, with package name `edu.gsu.classlab.auth_lab`.
Email/Password authentication is enabled for that project.

To connect your own Firebase project:

1. Create a Firebase project and enable **Authentication > Email/Password**.
2. Install the [Firebase CLI](https://firebase.google.com/docs/cli) and sign in with
   `firebase login`.
3. Install FlutterFire CLI with `dart pub global activate flutterfire_cli`.
4. From this repository's root, run:

```sh
flutter pub get
flutterfire configure --platforms=android --project=YOUR_PROJECT_ID
```

This regenerates `lib/firebase_options.dart` and
`android/app/google-services.json`. Firebase client configuration identifies the
backend; it does not grant administrator access. Do not commit account passwords,
service-account credentials, or private signing keys.

## Run

```sh
flutter pub get
flutter devices
flutter run -d YOUR_ANDROID_DEVICE_ID
```

Only Android is configured in this source. Configure Firebase for any additional
platform before running it there.

## Test

```sh
flutter analyze
flutter test
```

The four automated tests cover validation and safe error messages, loading and
repeated-tap prevention, profile access after sign-out, and simulated recent-login
recovery with incorrect and correct credentials.

Manual checks using a fictional test account:

1. Submit an invalid email, short password and mismatched confirmation. Confirm
   that validation prevents registration and explains what to fix.
2. Register a unique account. Confirm the profile shows its email.
3. Sign out, press Back, and reopen the app. Confirm the profile is unavailable.
4. Try an incorrect password, then the correct one. Confirm safe failure feedback
   and successful sign-in.
5. Change the password. Sign out and confirm the old password fails and the new
   password works.
6. Close and reopen the app while signed in, then while signed out. Confirm that
   each state is restored correctly.
7. Confirm requests show loading feedback and disable duplicate actions.
8. If Firebase returns `requires-recent-login`, try an incorrect current password,
   then the correct one. Confirm that reauthentication allows the update to retry.

The exact release APK passed the full account lifecycle and signed-in/signed-out
cold-start checks. A natural server recent-login challenge was not triggered; its
recovery path was checked with the simulated widget test.

## Build the Android APK

```sh
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

The main Android manifest includes INTERNET permission. The classroom release
build uses Flutter's debug signing key for direct installation; configure private
release signing for Play Store distribution.
