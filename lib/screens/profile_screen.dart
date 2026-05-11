import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/colors.dart';
import '../service/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileData;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _profileData = _authService.fetchUserProfile(widget.userId);
  }

  bool _isCurrentUser(String viewedUserUid) {
    return FirebaseAuth.instance.currentUser?.uid == viewedUserUid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: Text(
          "Profile",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final user = snapshot.data!;

          final bool isMe = _isCurrentUser(user['uid']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),

            child: Column(
              children: [
                // ================= HEADER =================
                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: AppColors.borderBlue),
                  ),

                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,

                        backgroundImage: AssetImage(
                          "assets/avatars/${user['profilePic']}",
                        ),
                      ),

                      const SizedBox(width: 14),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            user['name'],

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            user['email'],

                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= ECO CARD =================
                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                    ),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),

                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          LucideIcons.leaf,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              "Eco Score",

                              style: TextStyle(color: Colors.white70),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "${(user['ecoScore'] as num?)?.toStringAsFixed(4) ?? '0.0000'}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(height: 40, width: 1, color: Colors.white30),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              "CO₂ Saved",

                              style: TextStyle(color: Colors.white70),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "${(user['co2Saved'] as num?)?.toStringAsFixed(4) ?? '0.0000'} kg",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= STATS =================
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: AppColors.borderBlue),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,

                    children: [
                      _StatItem(
                        icon: LucideIcons.car,
                        value: "${user['ridesTaken']}",
                        label: "Rides",
                      ),

                      _StatItem(
                        icon: LucideIcons.users,
                        value: "${user['peopleSharedWith']}",
                        label: "People",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ================= LOGOUT =================
                if (isMe)
                  SizedBox(
                    width: double.infinity,
                    height: 54,

                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      },

                      icon: const Icon(
                        LucideIcons.logOut,
                        color: AppColors.error,
                      ),

                      label: const Text(
                        "Logout",

                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ================= STAT ITEM =================

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryBlue),

        const SizedBox(height: 6),

        Text(
          value,

          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        Text(
          label,

          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
