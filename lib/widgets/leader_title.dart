import 'package:flutter/material.dart';
import '../core/colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LeaderTile extends StatelessWidget {
  final String rank;
  final String name;
  final String points;
  final bool highlight;
  final String? profilePic;
  final int rankIndex;

  const LeaderTile({
    super.key,
    required this.rank,
    required this.name,
    required this.points,
    this.highlight = false,
    this.profilePic,
    this.rankIndex = 3, // Default to beyond top 3
  });

  @override
  Widget build(BuildContext context) {
    // Elegant medal styling derived from semantics, avoiding neon/gaming vibes
    Color medalColor = AppColors.avatarBg;
    Color highlightColor = AppColors.white;
    
    if (rankIndex == 0) {
      medalColor = AppColors.medalGold;
      highlightColor = AppColors.goldHighlight;
    } else if (rankIndex == 1) {
      medalColor = AppColors.medalSilver;
      highlightColor = AppColors.silverHighlight;
    } else if (rankIndex == 2) {
      medalColor = AppColors.medalBronze;
      highlightColor = AppColors.bronzeHighlight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? medalColor.withOpacity(0.5) : AppColors.borderBlue),
        color: highlight ? highlightColor : AppColors.white,
      ),
      child: Row(
        children: [
          // Rank / Medal Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medalColor,
            ),
            child: Center(
              child: highlight 
                  ? Icon(LucideIcons.medal, size: 14, color: AppColors.white)
                  : Text(
                      rank,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 10),

          CircleAvatar(
            radius: 18,
            backgroundImage: profilePic != null 
                ? AssetImage("assets/avatars/$profilePic")
                : const AssetImage("assets/avatars/earth.png") as ImageProvider,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Row(
            children: [
              Text(
                "$points pts",
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(LucideIcons.leaf, size: 14, color: AppColors.primaryGreen),
            ],
          )
        ],
      ),
    );
  }
}