import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/colors.dart';
import '../screens/chat_screen.dart';

class RideInProgressScreen extends StatelessWidget {
  const RideInProgressScreen({super.key});

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
        title: Column(
          children: [
            const Text(
              "Ride in Progress",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  "Active",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.messageSquare,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ROUTE SUMMARY CARD
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildRouteIndicator(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _locationRow(
                          "BMSCE, Basavanagudi",
                          "Pickup",
                          AppColors.primaryBlue,
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        _locationRow(
                          "Koramangala, Bangalore",
                          "Drop-off",
                          AppColors.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                  // const Icon(
                  //   Icons.chevron_right,
                  //   color: AppColors.textSecondary,
                  // ),
                ],
              ),
            ),
          ),

          // MAP SECTION (STATIC IMAGE WITH OVERLAYS)
          Expanded(
            child: Stack(
              children: [
                // Static Map Image Placeholder
                Positioned.fill(
                  child: Image(image: AssetImage('assets/maps.png')),
                ),

                // Blue Live Location Marker
                Positioned(
                  top: 200,
                  left: 80,
                  child: _mapMarker(
                    AppColors.primaryBlue,
                    "BMSCE\nBasavanagudi",
                  ),
                ),

                // Green Destination Marker
                Positioned(
                  top: 100,
                  right: 60,
                  child: const Icon(
                    LucideIcons.mapPin,
                    color: AppColors.primaryGreen,
                    size: 40,
                  ),
                ),

                // Car Icon and Bubble
                Positioned(
                  top: 150,
                  left: 160,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Column(
                          children: const [
                            Text(
                              "8 mins",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "away",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.car,
                        color: Colors.black,
                        size: 32,
                      ),
                    ],
                  ),
                ),

                // My Location Button
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM RIDE DETAILS CARD
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Your Ride Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Metro • 4 Seats",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _stackedAvatars(),
                  ],
                ),
                const Divider(height: 32, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoColumn("Started at", "05:30 PM"),
                    _infoColumn("Ride ID", "MET1234"),
                    _infoColumn("Fare", "₹60 / person"),
                  ],
                ),
                const SizedBox(height: 24),

                // CHAT BUTTON
                _gradientButton(context),

                const SizedBox(height: 12),

                // END RIDE BUTTON (REMOVED SHARE BUTTON)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.stop_circle_outlined,
                      color: Colors.red,
                    ),
                    label: const Text(
                      "End Ride",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildRouteIndicator() {
    return Column(
      children: [
        const Icon(
          Icons.radio_button_checked,
          color: AppColors.primaryBlue,
          size: 20,
        ),
        Container(width: 1, height: 30, color: AppColors.border),
        const Icon(LucideIcons.mapPin, color: AppColors.primaryGreen, size: 20),
      ],
    );
  }

  Widget _locationRow(String address, String label, Color tagColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            address,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tagColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: tagColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapMarker(Color color, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Icon(Icons.radio_button_checked, color: color, size: 24),
      ],
    );
  }

  Widget _stackedAvatars() {
    return Row(
      children: [
        ...List.generate(
          3,
          (i) => Transform.translate(
            offset: Offset(i * -12.0, 0),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage('../assets/maps.png'),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(-24, 0),
          child: const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Text(
              "+1",
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _gradientButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryGreen],
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen(rideId: "12333",)),
          );
        },
        icon: const Icon(LucideIcons.messageCircle, color: Colors.white),
        label: const Text(
          "Chat with Riders",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }
}
