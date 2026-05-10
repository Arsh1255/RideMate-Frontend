import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for StreamBuilder
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RideMateApp());
}

class RideMateApp extends StatelessWidget {
  const RideMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // --- THE AUTH GATE ---
      // This checks the session automatically every time the app opens
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // While Firebase is checking the local storage for a session
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If a user session exists
          if (snapshot.hasData) {
            final user = snapshot.data!;
            
            // Safety Check: If they logged in but never verified, send them back to verify
            if (!user.emailVerified) {
              return const VerificationScreen();
            }
            
            return const HomeScreen(); // Main destination[cite: 5]
          }

          // No user session found, show Login[cite: 5, 6]
          return const LoginScreen();
        },
      ),

      // Named routes for manual navigation[cite: 5]
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/verify': (context) => const VerificationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}