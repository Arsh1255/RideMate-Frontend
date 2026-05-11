import 'package:flutter/material.dart';
import '../../core/colors.dart';
import 'status_pill.dart';
import 'package:intl/intl.dart';

class CompactRideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onTap;

  const CompactRideCard({
    super.key,
    required this.ride,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final creator = ride['creatorId'];
    final name = creator != null ? creator['name'] ?? "Rider" : "Rider";
    final profilePic = creator != null ? creator['profilePic'] : null;
    
    final departureTime = DateTime.parse(ride['departureTime']);
    final timeStr = DateFormat('h:mm a').format(departureTime);
    final dateStr = DateFormat('E, d MMM').format(departureTime);

    String modeLabel = ride['mode'] ?? "N/A";
    if (modeLabel == 'publicTransportation') modeLabel = 'Public Transport';
    if (modeLabel == 'hasVehicle') modeLabel = 'Ride together';
    if (modeLabel == 'stride') modeLabel = 'Walk together';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: profilePic != null 
                        ? AssetImage("assets/avatars/$profilePic") 
                        : const AssetImage("assets/avatars/earth.png") as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(modeLabel, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                StatusPill(status: ride['status'] ?? 'created'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Image.asset('assets/icons/start.png', width: 16, height: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(ride['source']['address'] ?? "Unknown", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Image.asset('assets/icons/stop.png', width: 16, height: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(ride['destination']['address'] ?? "Unknown", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text("$dateStr • $timeStr", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.airline_seat_recline_normal, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text("${ride['availableSeats']} seats left", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
