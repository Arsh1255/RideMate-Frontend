import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/colors.dart';
import '../widgets/icons_gradient_button.dart';
import '../screens/ride_in_progress_screen.dart';

class MatchModel {
  final String name;
  final String distance;
  final String image;
  final Alignment alignment;

  MatchModel({
    required this.name,
    required this.distance,
    required this.image,
    required this.alignment,
  });
}

class FindingMatchesScreen extends StatefulWidget {
  const FindingMatchesScreen({super.key});

  @override
  State<FindingMatchesScreen> createState() => _FindingMatchesScreenState();
}

class _FindingMatchesScreenState extends State<FindingMatchesScreen>
    with SingleTickerProviderStateMixin {
  double _radius = 2.0;
  late AnimationController _rippleController;

  // Hardcoded profiles for the Radar
  final List<MatchModel> _matches = [
    MatchModel(
      name: "Priya Nair",
      distance: "1.2 km",
      image: "https://i.pravatar.cc/150?u=priya",
      alignment: const Alignment(0.6, -0.4),
    ),
    MatchModel(
      name: "Arjun Mehta",
      distance: "1.8 km",
      image: "https://i.pravatar.cc/150?u=arjun",
      alignment: const Alignment(-0.7, 0.1),
    ),
    MatchModel(
      name: "Rahul Sharma",
      distance: "2.4 km",
      image: "https://i.pravatar.cc/150?u=rahul",
      alignment: const Alignment(0.1, 0.7),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Finding matches...",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // RADAR SECTION
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildConcentricCircles(),

                // Central User Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                // Nearby Rider Avatars
                ..._matches.map(
                  (match) => Align(
                    alignment: match.alignment,
                    child: _buildRiderAvatar(match),
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM INFO & SLIDER SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.1),
                        AppColors.primaryGreen.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        color: AppColors.primaryBlue,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Scanning for eco-friendly riders...",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "We'll notify you when someone matches!",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Text(
                      "Ride within",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primaryBlue,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.primaryGreen,
                        ),
                        child: Slider(
                          value: _radius,
                          min: 1.0,
                          max: 10.0,
                          onChanged: (val) => setState(() => _radius = val),
                        ),
                      ),
                    ),
                    Text(
                      "${_radius.toStringAsFixed(1)} km",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔵 RIPPLE RADAR
  Widget _buildConcentricCircles() {
    return Stack(
      alignment: Alignment.center,
      children: [_buildRipple(0.0), _buildRipple(0.3), _buildRipple(0.6)],
    );
  }

  Widget _buildRipple(double delay) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (_, _) {
        final progress = (_rippleController.value + delay) % 1;

        final scale = 0.6 + (progress * 2.4);
        final opacity = (1 - progress).clamp(0.0, 1.0);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity * 0.35,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiderAvatar(MatchModel match) {
    return GestureDetector(
      onTap: () => _showMatchDetails(match),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(match.image),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          Text(
            match.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            match.distance,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showMatchDetails(MatchModel match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(match.image),
            ),
            const SizedBox(height: 12),
            Text(
              match.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "${match.distance} away",
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                children: [
                  _detailItem(
                    LucideIcons.car,
                    "Mode of Travel",
                    "Auto",
                    AppColors.primaryBlue,
                  ),
                  _detailItem(
                    LucideIcons.armchair,
                    "Seats Left",
                    "2 Seats",
                    AppColors.primaryGreen,
                  ),
                  _detailItem(
                    LucideIcons.clock,
                    "Time",
                    "05:30 PM",
                    Colors.purple,
                  ),
                  _detailItem(
                    LucideIcons.calendar,
                    "Date",
                    "Today, 24 May",
                    Colors.orange,
                  ),
                  _detailItem(
                    LucideIcons.leaf,
                    "EcoScore",
                    "4.8 / 5",
                    Colors.green,
                    trailing: "Excellent 🍃",
                  ),
                  _detailItem(
                    LucideIcons.users,
                    "Ride Preference",
                    "Comfortable • Eco-friendly",
                    AppColors.primaryBlue,
                  ),
                ],
              ),
            ),

            IconGradientButton(
              text: "Request Match",
              icon: LucideIcons.zap,
              onTap: () {
                Navigator.pop(context); // Close sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RideInProgressScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    String? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trailing,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
