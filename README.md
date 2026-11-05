# In-Class Activity 13: Firebase Authentication

Campus Access is a Flutter Android app for CSC 4360. Users can register, sign in,
view their account email, change their password, and sign out.

## Features

- `AuthService` keeps Firebase calls and the `authStateChanges()` stream in one place.
- The profile follows auth state, and Firebase restores the session when the app reopens.
- Forms check email format, the six-character password minimum, and password
  confirmation. Requests show loading feedback, prevent duplicate taps, and use
  safe error messages.
- Password changes support reauthentication and retry when Firebase requires a
  recent login.

The optional Firestore extension is not included.

## Setup

Built with Flutter 3.47.3 and Dart 3.13.3. You'll need Android Studio's SDK and
bundled Java runtime, plus an Android device or emulator.

Android Firebase configuration is included for `ica13-campus-access-blake`, using
package name `edu.gsu.classlab.auth_lab`. Email/Password sign-in must be enabled
under **Firebase Console > Authentication > Sign-in method**.

To use your own Firebase project, create it in the Firebase console, enable
Email/Password sign-in, and install the [Firebase CLI](https://firebase.google.com/docs/cli).
Then run these commands from the project folder:

```sh
flutter pub get
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android --project=YOUR_PROJECT_ID
```

This generates `lib/firebase_options.dart` and `android/app/google-services.json`.
Keep passwords, service-account credentials, and private signing keys out of Git.

## Run

```sh
flutter pub get
flutter devices
flutter run -d YOUR_ANDROID_DEVICE_ID
```

## Test

```sh
flutter analyze
flutter test
```

The four automated tests cover validation, safe errors, loading and duplicate-tap
prevention, signed-out profile access, and simulated recent-login recovery.

For a manual check with a test account:

1. Try invalid registration input, then register and check the profile email.
2. Sign out, press Back, and reopen the app; the profile should stay unavailable.
3. Try an incorrect password, then sign in with the correct one.
4. Change the password; confirm the old password fails and the new one works.
5. Reopen the app while signed in and while signed out; each state should persist.

The release APK passed the account flow and session-restoration checks. Firebase
hasn't triggered a natural recent-login challenge during testing; that recovery
path is covered by the simulated test.

## Build the APK

```sh
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

The main manifest includes Internet permission. This classroom build uses debug
signing; use private release signing for Play Store distribution.
