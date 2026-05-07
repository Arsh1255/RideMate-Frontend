import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String output = "Enter BMSCE email to start.";

  // --- SIGNUP LOGIC ---
  Future<void> signup() async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await cred.user!.sendEmailVerification();
      setState(() {
        output = "✅ Signup Initiated!\nEmail sent to: ${cred.user!.email}\nVerify then click 'CHECK VERIFICATION'.";
      });
    } catch (e) {
      setState(() => output = "SIGNUP ERROR:\n$e");
    }
  }

  // --- LOGIN LOGIC ---
  Future<void> login() async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = cred.user!;
      
      // Verify they aren't trying to bypass verification via login
      if (user.emailVerified) {
        final token = await user.getIdToken(true); // Get fresh token
        setState(() {
          output = "🔑 LOGIN SUCCESS!\n\nCOPY TOKEN FOR POSTMAN:\n\n$token";
        });
      } else {
        setState(() => output = "Login successful, but email is NOT verified. Check your inbox!");
      }
    } catch (e) {
      setState(() => output = "LOGIN ERROR:\n$e");
    }
  }

  // --- VERIFICATION CHECK ---
  Future<void> checkVerificationAndGetToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload(); 
        if (user.emailVerified) {
          final token = await user.getIdToken(true);
          setState(() => output = "🔥 VERIFIED!\n\nCOPY TOKEN FOR POSTMAN:\n\n$token");
        } else {
          setState(() => output = "❌ Not verified yet.");
        }
      }
    } catch (e) {
      setState(() => output = "CHECK ERROR:\n$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RideMate Auth Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "BMSCE Email")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 20),
            
            // Row of buttons to trigger functions
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(onPressed: signup, child: const Text("1. Signup")),
                ElevatedButton(onPressed: login, child: const Text("2. Login")),
                ElevatedButton(onPressed: checkVerificationAndGetToken, child: const Text("3. Check Verification")),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            Expanded(child: SingleChildScrollView(child: SelectableText(output))),
          ],
        ),
      ),
    );
  }
}