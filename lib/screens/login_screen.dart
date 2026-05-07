import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/colors.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';
import '../service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;
  bool isLoading = false;
  String? emailError;
  String? passwordError;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    setState(() { emailError = null; passwordError = null; isLoading = true; });

    if (!email.endsWith("@bmsce.ac.in")) {
      setState(() { emailError = "Use your college email (@bmsce.ac.in)"; isLoading = false; });
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      
      final response = await _authService.verifyWithBackend("");
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (response.statusCode == 403) {
        if (data['message'] == "Email not verified") {
          if (mounted) Navigator.pushNamed(context, '/verify');
        } else {
          setState(() => emailError = data['message']);
        }
      } else {
        setState(() => emailError = "Backend sync failed.");
      }
    } on FirebaseAuthException {
      setState(() => emailError = "Invalid email or password.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const SizedBox(height: 40),
            Stack(alignment: Alignment.center, children: [Image.asset("assets/members.png", width: 300, height: 230)]),
            const SizedBox(height: 20),
            const Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              "Login to continue your RideMate journey 🌱", 
              style: TextStyle(color: AppColors.textSecondary), 
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            CustomTextField(hint: "BMSCE Email", icon: LucideIcons.mail, errorText: emailError, controller: emailController),
            const SizedBox(height: 16),
            CustomTextField(
              hint: "Password", icon: LucideIcons.lock, obscure: obscure, controller: passwordController, errorText: passwordError,
              suffix: IconButton(icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye), onPressed: () => setState(() => obscure = !obscure)),
            ),
            const SizedBox(height: 30),
            isLoading ? const CircularProgressIndicator() : GradientButton(text: "Login", onTap: login),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/signup'), child: const Text("New here? Create Account")),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
}