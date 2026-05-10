import 'package:flutter/material.dart';
import '../../core/colors.dart';

class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.border;
    Color textColor = AppColors.textSecondary;
    String label = status;

    switch (status.toLowerCase()) {
      case 'created':
        bgColor = AppColors.primaryGreen.withOpacity(0.1);
        textColor = AppColors.primaryGreen;
        label = 'Active';
        break;
      case 'pending':
        bgColor = AppColors.warningBg;
        textColor = AppColors.warningText;
        label = 'Pending';
        break;
      case 'accepted':
        bgColor = AppColors.primaryBlue.withOpacity(0.1);
        textColor = AppColors.primaryBlue;
        label = 'Joined';
        break;
      case 'rejected':
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        label = 'Rejected';
        break;
      case 'completed':
        bgColor = AppColors.textSecondary.withOpacity(0.1);
        textColor = AppColors.textSecondary;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
