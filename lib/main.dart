import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(AuthLabApp(service: AuthService()));
  } catch (_) {
    // Fail closed: do not show a pretend authenticated app after setup failure.
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to start Firebase. Check the app configuration and restart.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
