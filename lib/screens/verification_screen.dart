// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/colors.dart';
import '../service/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final AuthService _authService = AuthService();

  bool isChecking = false;

  Future<void> checkVerification() async {
    setState(() {
      isChecking = true;
    });

    try {
      await FirebaseAuth.instance.currentUser?.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null) {
        if (!mounted) return;

        final args = ModalRoute.of(context)?.settings.arguments as Map?;

        final profilePic = (args != null && args["profilePic"] != null)
            ? args["profilePic"]
            : "earth.png";

        final response = await _authService.verifyWithBackend(profilePic);

        final data = jsonDecode(response.body);

        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Verification failed.")),
          );
        }
      }
    } catch (e) {
      print("VERIFICATION ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      if (mounted) {
        setState(() {
          isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Image.asset("assets/leaf.png", width: 140),

              const SizedBox(height: 24),

              Text(
                "Verify your email",

                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "We’ve sent a verification link to your BMSCE email.\nPlease verify to continue 🌱\n\nIf you can’t find the email, check your spam folder too.",

                textAlign: TextAlign.center,

                style: TextStyle(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 30),

              isChecking
                  ? const CircularProgressIndicator()
                  : const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isChecking ? null : checkVerification,

                child: const Text("I've Verified"),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

                  Navigator.pushReplacementNamed(context, '/login');
                },

                child: const Text("Cancel / Use different email"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
