import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/ride_card.dart';
import '../widgets/icons_gradient_button.dart';
import '../screens/find_ride_screen.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _onSearchTap(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => const FindRideScreen(),
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
    // 🔥 CURRENT USER ID (IMPORTANT)
    const currentUserId = "u0";

    // ---------------- MOCK DATA ----------------

    final users = {
      "u0": UserModel(
        uid: "u0",
        email: "arsh@mail.com",
        name: "Arsh",
        profilePic: "assets/profile.jpg",
        ecoScore: 100,
      ),
      "u1": UserModel(
        uid: "u1",
        email: "rahul@mail.com",
        name: "Rahul Sharma",
        profilePic: "assets/profile.jpg",
      ),
      "u2": UserModel(
        uid: "u2",
        email: "priya@mail.com",
        name: "Priya Nair",
        profilePic: "assets/profile.jpg",
      ),
    };

    final myRides = [
      Ride(
        rideId: "12333",
        rideName: "Morning Office Ride",
        pickup: "Koramangala, Bangalore",
        dropoff: "Majestic, Bangalore",
        departureTime: DateTime.now().add(const Duration(days: 1)),
        vehicleType: VehicleType.metro,
        mode: RideMode.publicTransportation,
        pricePerPerson: 60,
        availableSeats: 2,
        creatorId: "u0", // 👑 OWNER
        status: "ownerStarted",
        participantIds: ["u1", "u2"],
        pendingRequestIds: ["u2", "u1"],
      ),
      Ride(
        rideId: "12333",
        rideName: "Morning Office Ride",
        pickup: "Koramangala, Bangalore",
        dropoff: "Majestic, Bangalore",
        departureTime: DateTime.now().add(const Duration(days: 1)),
        vehicleType: VehicleType.metro,
        mode: RideMode.publicTransportation,
        pricePerPerson: 60,
        availableSeats: 2,
        creatorId: "u0", // 👑 OWNER
        status: "ownerActive",
        participantIds: ["u1", "u2"],
        pendingRequestIds: ["u2", "u1"],
      ),
      Ride(
        rideId: "45666",
        rideName: "BMSCE Stride",
        pickup: "Banashankari",
        dropoff: "BMSCE Campus",
        departureTime: DateTime.now().add(const Duration(hours: 3)),
        vehicleType: VehicleType.none,
        mode: RideMode.stride,
        pricePerPerson: 0,
        availableSeats: 1,
        creatorId: "other_user",
        status: "active",
        participantIds: ["u1", "u2"],
        pendingRequestIds: ["u1", ], // 👈 YOU REQUESTED
      ),
    ];

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/home'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // ---------------- TOP BAR ----------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(LucideIcons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        "Welcome, Arsh 👋",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage("assets/profile.jpg"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ---------------- LOCATION ----------------
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.borderBlue.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(LucideIcons.mapPin, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        "BMSCE, Basavanagudi",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ---------------- SEARCH ----------------
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
                            children: const [
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
                  onTap: () => Navigator.pushNamed(context, '/createRide'),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Your Rides",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                // ---------------- RIDE CARDS ----------------
                RideCard(
                  ride: myRides[0],
                  currentUserId: currentUserId,
                  users: users,
                ),

                const SizedBox(height: 16),

                RideCard(
                  ride: myRides[1],
                  currentUserId: currentUserId,
                  users: users,
                ),

                const SizedBox(height: 24),

                RideCard(
                  ride: myRides[2],
                  currentUserId: currentUserId,
                  users: users,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
