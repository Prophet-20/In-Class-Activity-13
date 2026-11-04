import 'package:firebase_auth/firebase_auth.dart';

class AuthSession {
  const AuthSession(this.uid, this.email);
  final String uid;
  final String email;
}

/// All credential operations stay here. Passwords are never written to storage.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _authStateChanges = _auth.authStateChanges().map(_session);
  }
  final FirebaseAuth _auth;
  late final Stream<AuthSession?> _authStateChanges;
  Stream<AuthSession?> get authStateChanges => _authStateChanges;
  static AuthSession? _session(User? user) => user == null
      ? null
      : AuthSession(user.uid, user.email ?? 'Email unavailable');
  AuthSession? get currentUser => _session(_auth.currentUser);

  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async => await _auth.signOut();
  User _requireUser() =>
      _auth.currentUser ??
      (throw FirebaseAuthException(code: 'no-current-user'));
  Future<void> updatePassword(String password) async {
    await _requireUser().updatePassword(password);
  }

  Future<void> reauthenticateAndUpdate(
    String current,
    String replacement,
  ) async {
    final user = _requireUser();
    final email = user.email;
    if (email == null) throw FirebaseAuthException(code: 'no-current-user');
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: current),
    );
    // The original update failed; retry only after reauthentication succeeds.
    await user.updatePassword(replacement);
  }
}

String authMessage(String code, {bool signingIn = false}) {
  if (signingIn &&
      const {
        'invalid-credential',
        'wrong-password',
        'user-not-found',
        'user-disabled',
        'invalid-login-credentials',
      }.contains(code)) {
    return 'Unable to sign in. Check your email and password and try again.';
  }
  return switch (code) {
    'invalid-email' => 'Enter an email address such as name@example.com.',
    'weak-password' || 'password-does-not-meet-requirements' =>
      'Choose a stronger password that meets this project’s password policy.',
    'email-already-in-use' =>
      'Unable to create this account. Try signing in or use another email.',
    'network-request-failed' => 'Check your internet connection and try again.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'operation-not-allowed' || 'configuration-not-found' =>
      'Email/password sign-in is unavailable. Contact the app administrator.',
    'requires-recent-login' => 'Confirm your current password to continue.',
    'invalid-credential' || 'wrong-password' || 'user-mismatch' =>
      'Unable to confirm your password. Check it and try again.',
    'no-current-user' || 'user-token-expired' || 'invalid-user-token' =>
      'Your session has expired. Sign out and sign in again.',
    _ => 'The request could not be completed. Please try again.',
  };
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? validatePassword(String? value) => (value?.length ?? 0) < 6
    ? 'Use at least 6 characters; project policy may require more.'
    : null;
