import 'package:flutter/material.dart';
import '../core/colors.dart';

class LeaderTile extends StatelessWidget {
  final String rank;
  final String name;
  final String points;
  final bool highlight;

  const LeaderTile({
    super.key,
    required this.rank,
    required this.name,
    required this.points,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderBlue),
        color: highlight ? const Color(0xFFFFF7E6) : Colors.white,
      ),
      child: Row(
        children: [
          // Rank
          CircleAvatar(
            radius: 14,
            backgroundColor:
                highlight ? Colors.orange : Colors.grey.shade300,
            child: Text(
              rank,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 10),

          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage("assets/profile.jpg"),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  "BMSCE",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Text(
            "$points pts",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}