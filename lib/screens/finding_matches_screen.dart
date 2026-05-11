import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../core/colors.dart';
import '../widgets/icons_gradient_button.dart';
import '../service/auth_service.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../widgets/ride/expanded_ride_sheet.dart';

class FindingMatchesScreen extends StatefulWidget {
  final Map<String, dynamic> searchParams;

  const FindingMatchesScreen({super.key, required this.searchParams});

  @override
  State<FindingMatchesScreen> createState() => _FindingMatchesScreenState();
}

class _FindingMatchesScreenState extends State<FindingMatchesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  bool _isLoading = true;
  List<dynamic> _matches = [];
  String _error = '';

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _searchRides();
  }

  Future<void> _searchRides() async {
    try {
      final response = await AuthService().searchRides(widget.searchParams);
      if (!mounted) return;
      setState(() {
        _matches = response['rides'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isLoading ? "Finding matches..." : "Matches Found",
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
                if (!_isLoading && _error.isEmpty)
                  ...List.generate(_matches.length, (index) {
                    final match = _matches[index];
                    // Generate random alignments for visualization
                    final alignments = [
                      const Alignment(0.6, -0.4),
                      const Alignment(-0.7, 0.1),
                      const Alignment(0.1, 0.7),
                      const Alignment(-0.3, -0.6),
                      const Alignment(0.5, 0.5),
                    ];
                    final alignment = alignments[index % alignments.length];
                    
                    return Align(
                      alignment: alignment,
                      child: _buildRiderAvatar(match),
                    );
                  }),
                  
                if (_error.isNotEmpty)
                  _buildErrorOverlay(_error),
                  
                if (!_isLoading && _matches.isEmpty && _error.isEmpty)
                  Center(child: Text("No matches found", style: TextStyle(color: AppColors.textSecondary))),
              ],
            ),
          ),

          // BOTTOM INFO
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
                          children: [
                            Text(
                              _isLoading ? "Scanning for eco-friendly riders..." : "Scan Complete",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _isLoading ? "We'll notify you when someone matches!" : "Found ${_matches.length} matches nearby",
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcentricCircles() {
    return Stack(
      alignment: Alignment.center,
      children: [_buildRipple(0.0), _buildRipple(0.3), _buildRipple(0.6)],
    );
  }

  Widget _buildErrorOverlay(String error) {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
              child: const Icon(Icons.close, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text("Search Failed", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(error, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = '';
                  _isLoading = true;
                });
                _searchRides();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
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

  Widget _buildRiderAvatar(dynamic match) {
    final creator = match['creatorId'];
    final name = creator != null ? creator['name'] ?? "Rider" : "Rider";
    final profilePic = creator != null ? creator['profilePic'] : null;
    
    return GestureDetector(
      onTap: () => _showMatchDetails(match),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: profilePic != null 
                  ? AssetImage("assets/avatars/$profilePic") 
                  : const AssetImage("assets/avatars/earth.png") as ImageProvider,
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
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            match['mode'] ?? "Ride",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showMatchDetails(dynamic match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpandedRideSheet(
        rideId: match['_id'],
        seatsRequested: widget.searchParams['seatsNeeded'],
        pickupLocation: {
          'address': 'Selected Location',
          'coordinates': widget.searchParams['source']
        },
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
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
                style: TextStyle(
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
