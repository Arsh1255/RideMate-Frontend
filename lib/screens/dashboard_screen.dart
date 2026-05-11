import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/colors.dart';
import '../widgets/leader_title.dart';
import '../widgets/app_drawer.dart';
import '../service/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  double _totalCo2Saved = 0.0;
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await AuthService().fetchDashboardData();
      setState(() {
        _totalCo2Saved = (data['totalCo2Saved'] ?? 0).toDouble();
        _leaderboard = data['leaderboard'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching dashboard data: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatCo2(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 🔹 TOP BAR
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(LucideIcons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "RideMate Dashboard",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for menu icon
                ],
              ),

              const SizedBox(height: 20),

              // 🔹 ECO CARD (Hero)
              Container(
                width: double.infinity,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative SVG pattern
                    Positioned.fill(
                      child: SvgPicture.asset(
                        "assets/patterns/dashboard_hero.svg",
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.leaf, color: AppColors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total CO₂ Saved",
                                style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14), // Colors.white70 is 0xB3FFFFFF
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${_formatCo2(_totalCo2Saved)} kg",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                child: _leaderboard.isEmpty
                    ? Center(child: Text("No leaderboard data yet.", style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        itemCount: _leaderboard.length,
                        itemBuilder: (context, index) {
                          final user = _leaderboard[index];
                          final rank = index + 1;
                          final name = user['name'] ?? "Unknown User";
                          final rawScore = user['ecoScore'] ?? 0;
                          final double scoreDouble = rawScore is num ? rawScore.toDouble() : (double.tryParse(rawScore.toString()) ?? 0.0);
                          final points = scoreDouble == scoreDouble.truncateToDouble() 
                              ? scoreDouble.toInt().toString() 
                              : scoreDouble.toStringAsFixed(2);
                          
                          // Handle medal styling
                          bool isTop3 = rank <= 3;
                          return LeaderTile(
                            rank: rank.toString(),
                            name: name,
                            points: points,
                            highlight: isTop3,
                            rankIndex: index,
                            profilePic: user['profilePic'],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
