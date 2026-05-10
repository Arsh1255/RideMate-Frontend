import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/colors.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool obscure = true;
  bool isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? emailError;
  String? serverError;

  bool hasMinLength = false;
  bool hasLettersAndNumbers = false;

  final List<String> avatars = [
    "rocket.png",
    "boy.png",
    "girl.png",
    "headphones.png",
    "earth.png",
    "music.png",
  ];

  int selectedAvatarIndex = 0;

  final PageController _avatarController =
      PageController(viewportFraction: 0.38);

  void validateEmail() {
    final email = emailController.text.trim();

    if (!email.endsWith("@bmsce.ac.in")) {
      setState(() {
        emailError =
            "Use your college email (@bmsce.ac.in)";
      });
    } else {
      setState(() {
        emailError = null;
      });
    }
  }

  void validatePassword(String value) {
    setState(() {
      hasMinLength = value.length >= 8;

      hasLettersAndNumbers =
          RegExp(r'^(?=.*[A-Za-z])(?=.*\d)')
              .hasMatch(value);
    });
  }

  Future<void> signup() async {
    final name = nameController.text.trim();

    validateEmail();

    if (name.isEmpty) {
      setState(() {
        serverError = "Please enter your full name";
      });
      return;
    }

    if (emailError != null ||
        !hasMinLength ||
        !hasLettersAndNumbers) {
      return;
    }

    setState(() {
      serverError = null;
      isLoading = true;
    });

    try {
      UserCredential credential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: emailController.text.trim(),
                password:
                    passwordController.text.trim(),
              );

      await credential.user!
          .updateDisplayName(name);

      await credential.user!
          .sendEmailVerification();

      final selectedAvatar =
          avatars[selectedAvatarIndex];

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/verify',
          arguments: {
            "profilePic": selectedAvatar,
          },
        );
      }

    } on FirebaseAuthException catch (e) {

      setState(() {
        serverError =
            e.code == 'email-already-in-use'
            ? "Email already registered. Login instead."
            : (e.message ?? "Signup failed.");
      });

    } catch (e) {

      setState(() {
        serverError =
            "Something went wrong. Please try again.";
      });

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20),

          child: Column(
            children: [
              const SizedBox(height: 10),

              

              const SizedBox(height: 10),

              Text(
                "Choose Your Avatar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 150,

                child: PageView.builder(
                  controller: _avatarController,
                  itemCount: avatars.length,

                  onPageChanged: (index) {
                    setState(() {
                      selectedAvatarIndex = index;
                    });
                  },

                  itemBuilder: (context, index) {

                    final isSelected =
                        index == selectedAvatarIndex;

                    return AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 250),

                      margin: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: isSelected ? 0 : 18,
                      ),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGreen
                              : Colors.transparent,
                          width: 3,
                        ),

                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryGreen
                                      .withValues(alpha: 0.22),

                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),

                      child: AnimatedScale(
                        duration:
                            const Duration(milliseconds: 250),

                        scale: isSelected ? 1.0 : 0.72,

                        child: ClipOval(
                          child: Image.asset(
                            "assets/avatars/${avatars[index]}",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Join RideMate and start your eco-friendly journey 🌱",
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Full Name"),
              ),

              const SizedBox(height: 6),

              CustomTextField(
                hint: "Your Name",
                icon: LucideIcons.user,
                controller: nameController,
              ),

              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text("BMSCE Email"),
              ),

              const SizedBox(height: 6),

              CustomTextField(
                hint: "yourname@bmsce.ac.in",
                icon: LucideIcons.mail,
                errorText: emailError,
                controller: emailController,
              ),

              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Password"),
              ),

              const SizedBox(height: 6),

              CustomTextField(
                hint: "Password",
                icon: LucideIcons.lock,
                obscure: obscure,
                controller: passwordController,
                onChanged: validatePassword,

                suffix: IconButton(
                  icon: Icon(
                    obscure
                        ? LucideIcons.eyeOff
                        : LucideIcons.eye,
                  ),

                  onPressed: () {
                    setState(() {
                      obscure = !obscure;
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    hasMinLength
                        ? Icons.check_circle
                        : Icons.cancel,

                    color: hasMinLength
                        ? Colors.green
                        : Colors.grey,

                    size: 16,
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    "At least 8 characters",
                  ),
                ],
              ),

              Row(
                children: [
                  Icon(
                    hasLettersAndNumbers
                        ? Icons.check_circle
                        : Icons.circle_outlined,

                    color: hasLettersAndNumbers
                        ? Colors.green
                        : Colors.grey,

                    size: 16,
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    "Include letters and numbers",
                  ),
                ],
              ),

              const SizedBox(height: 24),

              isLoading
                  ? const CircularProgressIndicator()
                  : GradientButton(
                      text: "Signup",
                      onTap: signup,
                    ),

              const SizedBox(height: 16),

              if (serverError != null)
                Container(
                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          serverError!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  const Text(
                    "Already have an account? ",
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },

                    child: const Text(
                      "Login",

                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}