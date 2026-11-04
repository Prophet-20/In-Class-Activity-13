import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth_lab/app.dart';
import 'package:auth_lab/services/auth_service.dart';

class FakeAuth implements AuthService {
  final changes = StreamController<AuthSession?>.broadcast();
  AuthSession? session;
  int calls = 0;
  bool requireRecent = false;
  Completer<void>? pending;
  @override
  Stream<AuthSession?> get authStateChanges => changes.stream;
  @override
  AuthSession? get currentUser => session;
  void emit(AuthSession? value) {
    session = value;
    changes.add(value);
  }

  @override
  Future<void> signIn(String email, String password) async {
    calls++;
    await pending?.future;
    throw FirebaseAuthException(code: 'invalid-credential');
  }

  @override
  Future<void> register(String email, String password) async {
    calls++;
  }

  @override
  Future<void> signOut() async => emit(null);
  @override
  Future<void> updatePassword(String value) async {
    if (requireRecent) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
  }

  @override
  Future<void> reauthenticateAndUpdate(
    String current,
    String replacement,
  ) async {
    calls++;
    if (current != 'correct-current') {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
  }
}

void main() {
  test('validation boundaries and privacy-aware error mapping', () {
    expect(validateEmail(' test@example.com '), isNull);
    for (final email in ['', 'hello', 'a@@b.com', 'a b@c.com']) {
      expect(validateEmail(email), isNotNull);
    }
    expect(validatePassword('12345'), isNotNull);
    expect(validatePassword('123456'), isNull);
    expect(
      authMessage('wrong-password', signingIn: true),
      authMessage('user-not-found', signingIn: true),
    );
    expect(
      authMessage('secret-server-detail'),
      isNot(contains('secret-server-detail')),
    );
  });
  testWidgets(
    'loading prevents duplicate calls and shows safe credential error',
    (tester) async {
      final fake = FakeAuth();
      addTearDown(fake.changes.close);
      await tester.pumpWidget(AuthLabApp(service: fake));
      fake.emit(null);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('email')),
        'tester@example.com',
      );
      await tester.enterText(find.byKey(const Key('password')), 'bad-password');
      fake.pending = Completer<void>();
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pump();
      expect(find.text('Connecting securely…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('submit'))).onPressed,
        isNull,
      );
      expect(fake.calls, 1);
      fake.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Unable to sign in.'), findsOneWidget);
    },
  );
  testWidgets(
    'auth state removes profile and a fresh tree still gates access',
    (tester) async {
      final fake = FakeAuth();
      addTearDown(fake.changes.close);
      await tester.pumpWidget(AuthLabApp(service: fake));
      fake.emit(const AuthSession('one', 'tester@example.com'));
      await tester.pumpAndSettle();
      expect(find.text('tester@example.com'), findsOneWidget);
      fake.emit(null);
      await tester.pumpAndSettle();
      expect(find.text('Your profile'), findsNothing);
      expect(find.text('Welcome back'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Your profile'), findsNothing);
    },
  );
  testWidgets(
    'recent login asks for current password, retries, and clears secrets',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakeAuth()..requireRecent = true;
      addTearDown(fake.changes.close);
      await tester.pumpWidget(AuthLabApp(service: fake));
      fake.emit(const AuthSession('one', 'tester@example.com'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('new-password')),
        'replacement-pass',
      );
      await tester.enterText(
        find.byKey(const Key('confirm-new')),
        'replacement-pass',
      );
      await tester.tap(find.byKey(const Key('update')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('current-password')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('current-password')),
        'wrong',
      );
      await tester.tap(find.byKey(const Key('update')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Unable to confirm your password.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('current-password')),
        'correct-current',
      );
      await tester.tap(find.byKey(const Key('update')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Password updated.'), findsOneWidget);
      expect(find.byKey(const Key('current-password')), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('new-password')))
            .controller!
            .text,
        isEmpty,
      );
      expect(fake.calls, 2);
    },
  );
}
