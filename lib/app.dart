import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/auth_service.dart';

const burgundy = Color(0xff641e24);

class AuthLabApp extends StatelessWidget {
  const AuthLabApp({super.key, required this.service});
  final AuthService service;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Campus Access',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: burgundy),
      scaffoldBackgroundColor: const Color(0xfffbf3e8),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      ),
    ),
    home: StreamBuilder<AuthSession?>(
      stream: service.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to restore your session. Restart the app and try again.',
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Restoring your session…'),
                ],
              ),
            ),
          );
        }
        final session = snapshot.data;
        return session == null
            ? SignInScreen(service: service)
            : ProfileScreen(
                key: ValueKey(session.uid),
                service: service,
                session: session,
              );
      },
    ),
  );
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('CAMPUS ACCESS'),
      backgroundColor: burgundy,
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 44,
                    color: burgundy,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: burgundy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 28),
                ...children,
                const SizedBox(height: 24),
                const Text(
                  'CSC 4360 · Firebase Authentication',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xff705b50)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class FeedbackBox extends StatelessWidget {
  const FeedbackBox(this.message, {super.key, this.success = false});
  final String message;
  final bool success;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: success ? const Color(0xffe5f1e4) : const Color(0xffffe6de),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: success ? const Color(0xff215122) : burgundy),
      ),
    ),
  );
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.service});
  final AuthService service;
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool register = false, busy = false;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (register) {
        await widget.service.register(email.text, password.text);
      } else {
        await widget.service.signIn(email.text, password.text);
      }
      // The auth stream alone changes the screen; no pushed profile route remains.
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => message = authMessage(error.code, signingIn: !register));
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = 'Unable to connect. Please try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: register ? 'Create your account' : 'Welcome back',
    subtitle: register
        ? 'One account. Your own space.'
        : 'Sign in to open your profile.',
    children: [
      if (message != null) FeedbackBox(message!),
      Form(
        key: form,
        child: Column(
          children: [
            TextFormField(
              key: const Key('email'),
              controller: email,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              validator: validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('password'),
              controller: password,
              enabled: !busy,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              validator: register
                  ? validatePassword
                  : (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
              onFieldSubmitted: (_) {
                if (!register) submit();
              },
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (register) ...[
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('confirm'),
                controller: confirm,
                enabled: !busy,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                validator: (value) =>
                    value != password.text ? 'Passwords must match.' : null,
                onFieldSubmitted: (_) => submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'At least 6 characters. A stronger project policy may apply.',
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('submit'),
              onPressed: busy ? null : submit,
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(register ? 'Create account' : 'Sign in'),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Connecting securely…'),
              ),
            const SizedBox(height: 12),
            TextButton(
              key: const Key('switch'),
              onPressed: busy
                  ? null
                  : () {
                      setState(() {
                        register = !register;
                        message = null;
                        password.clear();
                        confirm.clear();
                        form.currentState?.reset();
                      });
                    },
              child: Text(
                register
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Your profile is available only while you are signed in.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.service,
    required this.session,
  });
  final AuthService service;
  final AuthSession session;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final form = GlobalKey<FormState>();
  final replacement = TextEditingController(),
      confirm = TextEditingController(),
      current = TextEditingController();
  bool busy = false, needsRecentLogin = false, success = false;
  String? message;
  @override
  void dispose() {
    replacement.dispose();
    confirm.dispose();
    current.dispose();
    super.dispose();
  }

  Future<void> update() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      message = null;
      success = false;
    });
    try {
      if (needsRecentLogin) {
        await widget.service.reauthenticateAndUpdate(
          current.text,
          replacement.text,
        );
      } else {
        await widget.service.updatePassword(replacement.text);
      }
      if (!mounted) return;
      replacement.clear();
      confirm.clear();
      current.clear();
      setState(() {
        needsRecentLogin = false;
        success = true;
        message = 'Password updated. Use your new password the next time you sign in.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.code == 'requires-recent-login') needsRecentLogin = true;
        message = authMessage(error.code);
      });
    } catch (_) {
      if (mounted) {
        setState(() => message = 'Unable to update your password. Try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> signOut() async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
      success = false;
    });
    try {
      await widget.service.signOut();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => message = authMessage(error.code));
    } catch (_) {
      if (mounted) setState(() => message = 'Unable to sign out. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Your profile',
    subtitle: 'You are signed in.',
    children: [
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACCOUNT EMAIL',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.session.email,
                key: const Key('profile-email'),
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Change password',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text('Choose at least 6 characters. Keep your password private.'),
      const SizedBox(height: 16),
      if (message != null) FeedbackBox(message!, success: success),
      Form(
        key: form,
        child: Column(
          children: [
            if (needsRecentLogin) ...[
              TextFormField(
                key: const Key('current-password'),
                controller: current,
                enabled: !busy,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your current password.'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              key: const Key('new-password'),
              controller: replacement,
              enabled: !busy,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              validator: validatePassword,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('confirm-new'),
              controller: confirm,
              enabled: !busy,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              validator: (value) =>
                  value != replacement.text ? 'Passwords must match.' : null,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('update'),
              onPressed: busy ? null : update,
              child: Text(
                needsRecentLogin
                    ? 'Confirm and update password'
                    : 'Update password',
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        key: const Key('signout'),
        onPressed: busy ? null : signOut,
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
    ],
  );
}
