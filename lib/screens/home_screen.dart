import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/colors.dart';
import '../widgets/app_drawer.dart';
import '../core/theme_mode_notifier.dart';
import '../widgets/icons_gradient_button.dart';
import '../screens/request_ride_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/post_ride_screen.dart';

import '../service/auth_service.dart';
import '../widgets/ride/home_ride_card.dart';
import '../widgets/ride/expanded_ride_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/socket_service.dart';
import '../widgets/ride/ride_completion_overlay.dart';

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

  void _onStandardEvent(dynamic data) {
    if (mounted) _fetchHomeRides();
  }

  void _onRequestAccepted(dynamic data) {
    if (mounted) {
      _fetchHomeRides();
      if (data is Map && data['rideId'] != null) {
        SocketService().joinRide(data['rideId']);
      }
    }
  }

  void _onRideCompleted(dynamic data) {
    if (mounted) {
      _fetchHomeRides();
      
      if (data is Map && data['ecoScoreGained'] != null) {
        final double ecoScore = (data['ecoScoreGained'] as num).toDouble();
        final double co2 = (data['co2Saved'] as num).toDouble();
        
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: AppColors.white.withOpacity(0.9),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: RideCompletionOverlay(
                ecoScoreGained: ecoScore,
                co2Saved: co2,
                onDismiss: () => Navigator.pop(context),
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _setupSocket() async {
    await SocketService().connect();
    
    SocketService().on('RIDE_STARTED', _onStandardEvent);
    SocketService().on('RIDE_COMPLETED', _onRideCompleted);
    SocketService().on('RIDE_CANCELLED', _onStandardEvent);
    SocketService().on('REQUEST_ACCEPTED', _onRequestAccepted);
    SocketService().on('REQUEST_REJECTED', _onStandardEvent);
  }

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fetchUserData();
    _fetchHomeRides();
    
    _setupSocket();
    themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    SocketService().off('RIDE_STARTED', _onStandardEvent);
    SocketService().off('RIDE_COMPLETED', _onRideCompleted);
    SocketService().off('RIDE_CANCELLED', _onStandardEvent);
    SocketService().off('REQUEST_ACCEPTED', _onRequestAccepted);
    SocketService().off('REQUEST_REJECTED', _onStandardEvent);
    
    _rotationController.dispose();
    themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      _fetchHomeRides();
    }
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

  void _showRideDetails(String rideId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpandedRideSheet(rideId: rideId),
    );
    _fetchHomeRides();
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

  void _onSearchTap(BuildContext context) async {
    await Navigator.push(
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
    _fetchHomeRides();
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
              child: Icon(LucideIcons.refreshCw, color: AppColors.white, size: 22),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),

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
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              userId: FirebaseAuth.instance.currentUser!.uid,
                            ),
                          ),
                        );
                        _fetchUserData();
                      },

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

                          child: Row(
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
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PostRideScreen()),
                    );
                    _fetchHomeRides();
                  },
                ),

                const SizedBox(height: 30),

                // ---------------- YOUR RIDES ----------------
                const Text(
                  "Your Rides",

                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: _isLoadingRides
                    ? const Center(child: CircularProgressIndicator())
                    : _rides.isEmpty
                        ? Center(
                            child: Text(
                              "No rides found. Create or join one!",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 40),
                            itemCount: _rides.length,
                            itemBuilder: (context, index) {
                              final ride = _rides[_rides.length - 1 - index];
                              return _buildRideCard(ride);
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
