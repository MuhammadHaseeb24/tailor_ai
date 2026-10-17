import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth.dart';
import 'screens/shell.dart';
import 'ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TailorAiApp());
}

class TailorAiApp extends StatelessWidget {
  const TailorAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TailorAI',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.hasData ? const Shell() : const LoginScreen();
        },
      ),
    );
  }
}
