import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/colors.dart';
import '../widgets/leader_title.dart';
import '../widgets/app_drawer.dart'; // 👈 ADD THIS

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ✅ FIX: real drawer added
      drawer: const AppDrawer(currentRoute: '/dashboard'),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 🔹 TOP BAR
              Row(
                children: [
                  // LEFT: menu button
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(LucideIcons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),

                  // CENTER: title (flexible, prevents overflow)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "RideMate Dashboard",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // RIGHT: score + profile
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderBlue),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              LucideIcons.leaf,
                              size: 14,
                              color: Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text("320"),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      const CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage("assets/profile.jpg"),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔹 ECO CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.leaf, color: Colors.white, size: 32),
                    const SizedBox(width: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Total CO₂ Saved",
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "14.2 kg",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "You're in the top 5% of BMSCE!",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Eco-Leaderboard",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  children: const [
                    LeaderTile(
                      rank: "1",
                      name: "Arsh",
                      points: "1420",
                      highlight: true,
                    ),
                    LeaderTile(rank: "2", name: "Ash", points: "1280"),
                    LeaderTile(rank: "3", name: "Lufi", points: "1150"),
                    LeaderTile(
                      rank: "4",
                      name: "Monkey de lufey",
                      points: "980",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
