import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../gradient_button.dart';
import '../icons_gradient_button.dart';
import '../ride_outline_button.dart';
import 'status_pill.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeRideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onMoreInfo;
  final VoidCallback? onStartRide;
  final VoidCallback? onCancelRide;
  final VoidCallback? onLeaveRide;
  final VoidCallback? onEndRide;

  const HomeRideCard({
    super.key,
    required this.ride,
    required this.onMoreInfo,
    this.onStartRide,
    this.onCancelRide,
    this.onLeaveRide,
    this.onEndRide,
  });

  @override
  Widget build(BuildContext context) {
    final relationship = ride['relationship'];
    final membershipStatus = ride['membershipStatus'];
    final rideStatus = ride['rideStatus'] ?? 'created';

    final isOwner = relationship == 'owner';
    final isAccepted = membershipStatus == 'accepted';
    
    final departureTime = DateTime.parse(ride['departureTime']);
    final timeStr = DateFormat('h:mm a').format(departureTime);
    final dateStr = DateFormat('E, d MMM').format(departureTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ride['rideName'] ?? "Ride", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Ride ID: ${ride['id'].toString().substring(ride['id'].toString().length - 5)}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              StatusPill(status: rideStatus),
            ],
          ),
          const SizedBox(height: 16),

          // Route
          Row(
            children: [
              Image.asset('assets/icons/start.png', width: 16, height: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(ride['source']['name'] ?? ride['source']['address'] ?? "Unknown", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Image.asset('assets/icons/stop.png', width: 16, height: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(ride['destination']['name'] ?? ride['destination']['address'] ?? "Unknown", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
            ],
          ),
          const SizedBox(height: 16),

          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text("$dateStr • $timeStr", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.airline_seat_recline_normal, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text("${ride['availableSeats']} Seats", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.currency_rupee, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text("₹${ride['pricePerPerson'] ?? 0} per person", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),

          if (rideStatus == 'started') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.mapPin, color: AppColors.primaryBlue, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Ride's started",
                    style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Actions
          if (rideStatus == 'created') ...[
            if (isOwner) ...[
              Row(
                children: [
                  Expanded(
                    child: IconGradientButton(
                      text: "Start Ride",
                      icon: LucideIcons.play,
                      onTap: onStartRide ?? () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RideOutlineButton(
                      text: "More Info",
                      onTap: onMoreInfo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: RideOutlineButton(
                  text: "Cancel Ride",
                  onTap: onCancelRide ?? () {},
                  isDestructive: true,
                ),
              ),
            ] else if (isAccepted) ...[
              Row(
                children: [
                  Expanded(
                    child: RideOutlineButton(
                      text: "More Info",
                      onTap: onMoreInfo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RideOutlineButton(
                      text: "Leave Ride",
                      onTap: onLeaveRide ?? () {},
                      isDestructive: true,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Pending or Rejected
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "Confirmation Pending",
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RideOutlineButton(
                      text: "More Info",
                      onTap: onMoreInfo,
                    ),
                  ),
                ],
              ),
            ],
          ] else if (rideStatus == 'started') ...[
            if (isOwner) ...[
              Row(
                children: [
                  Expanded(
                    child: IconGradientButton(
                      text: "End Ride",
                      icon: LucideIcons.check,
                      onTap: onEndRide ?? () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RideOutlineButton(
                      text: "More Info",
                      onTap: onMoreInfo,
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: IconGradientButton(
                  text: "Ongoing Ride",
                  icon: LucideIcons.mapPin,
                  onTap: onMoreInfo,
                ),
              ),
            ],
          ] else ...[
            // Completed or Cancelled
            SizedBox(
              width: double.infinity,
              child: RideOutlineButton(
                text: "More Info",
                onTap: onMoreInfo,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
