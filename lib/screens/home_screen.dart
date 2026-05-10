import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/icons_gradient_button.dart';
import '../screens/request_ride_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/post_ride_screen.dart';

import '../service/auth_service.dart';
import '../widgets/ride/home_ride_card.dart';
import '../widgets/ride/expanded_ride_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _userProfile;
  bool _isLoadingUser = true;
  List<dynamic> _rides = [];
  bool _isLoadingRides = true;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fetchUserData();
    _fetchHomeRides();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final data = await AuthService().fetchUserProfile(uid);
        setState(() {
          _userProfile = data;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _fetchHomeRides() async {
    _rotationController.repeat();
    setState(() => _isLoadingRides = true);
    try {
      final data = await AuthService().fetchHomeRides();
      setState(() {
        _rides = data['rides'] ?? [];
        _isLoadingRides = false;
      });
    } catch (e) {
      print("Error fetching home rides: $e");
      setState(() => _isLoadingRides = false);
    } finally {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  Widget _buildRideCard(dynamic ride) {
    return HomeRideCard(
      ride: ride,
      onMoreInfo: () => _showRideDetails(ride['id']),
      onStartRide: () => _startRide(ride['id']),
      onCancelRide: () => _cancelRide(ride['id']),
      onLeaveRide: () => _leaveRide(ride['id']),
      onEndRide: () => _endRide(ride['id']),
    );
  }

  void _showRideDetails(String rideId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpandedRideSheet(rideId: rideId),
    );
  }

  Future<void> _startRide(String rideId) async {
    try {
      await AuthService().startRide(rideId);
      _showSnackBar("Ride started!", isError: false);
      await _fetchHomeRides(); // Refresh
    } catch (e) {
      _showSnackBar("Failed to start ride: $e", isError: true);
    }
  }

  Future<void> _endRide(String rideId) async {
    try {
      await AuthService().completeRide(rideId);
      _showSnackBar("Ride completed!", isError: false);
      await _fetchHomeRides(); // Refresh
    } catch (e) {
      _showSnackBar("Failed to complete ride: $e", isError: true);
    }
  }

  Future<void> _cancelRide(String rideId) async {
    try {
      await AuthService().cancelRide(rideId);
      _showSnackBar("Ride cancelled.", isError: false);
      await _fetchHomeRides(); // Refresh
    } catch (e) {
      _showSnackBar("Failed to cancel ride: $e", isError: true);
    }
  }

  Future<void> _leaveRide(String rideId) async {
    try {
      await AuthService().leaveRide(rideId);
      _showSnackBar("You have left the ride.", isError: false);
      await _fetchHomeRides(); // Refresh
    } catch (e) {
      _showSnackBar("Failed to leave ride: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSearchTap(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),

        pageBuilder: (_, _, _) => const RequestRideScreen(),

        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,

            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),

                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),

              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/home'),
      backgroundColor: AppColors.background,
      floatingActionButton: GestureDetector(
        onTap: _isLoadingRides ? null : _fetchHomeRides,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: RotationTransition(
              turns: _rotationController,
              child: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 10),

                // ---------------- TOP BAR ----------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Builder(
                      builder: (context) {
                        return IconButton(
                          icon: const Icon(LucideIcons.menu),

                          onPressed: () => Scaffold.of(context).openDrawer(),
                        );
                      },
                    ),

                    const Expanded(
                      child: Text(
                        "Welcome 👋",

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            userId: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ),
                      ),

                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: _userProfile != null && _userProfile!['profilePic'] != null
                          ? AssetImage("assets/avatars/${_userProfile!['profilePic']}")
                          : const AssetImage("assets/avatars/earth.png") as ImageProvider,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // ---------------- SEARCH BAR ----------------
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onSearchTap(context),

                        child: Container(
                          padding: const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),

                            border: Border.all(
                              color: AppColors.borderBlue.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),

                          child: const Row(
                            children: [
                              Icon(LucideIcons.search, size: 20),

                              SizedBox(width: 10),

                              Text(
                                "Where do you wanna go?",

                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    GestureDetector(
                      onTap: () => _onSearchTap(context),

                      child: Container(
                        padding: const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),

                          border: Border.all(
                            color: AppColors.borderBlue.withValues(alpha: 0.5),
                          ),
                        ),

                        child: const Icon(LucideIcons.target),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ---------------- CREATE RIDE ----------------
                IconGradientButton(
                  text: "Or Create One Yourself",

                  icon: LucideIcons.plus,

                  onTap: () => Navigator.push(
                    context,

                    MaterialPageRoute(builder: (_) => const PostRideScreen()),
                  ),
                ),

                const SizedBox(height: 30),

                // ---------------- YOUR RIDES ----------------
                const Text(
                  "Your Rides",

                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                _isLoadingRides
                  ? const Center(child: CircularProgressIndicator())
                  : _rides.isEmpty
                      ? const Center(
                          child: Text(
                            "No rides found. Create or join one!",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : Column(
                          children: _rides.map((ride) => _buildRideCard(ride)).toList(),
                        ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
