import 'package:flutter/material.dart';
import '../core/colors.dart';

class RideOutlineButton extends StatelessWidget {
  final String text;
  final String? routeName; // The named route to navigate to
  final Object? arguments; // Optional data to pass to the next screen
  final VoidCallback? onTap; // For actions other than navigation
  final bool isFullWidth;

  const RideOutlineButton({
    super.key,
    required this.text,
    this.routeName,
    this.arguments,
    this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
      onPressed: () {
        if (routeName != null) {
          Navigator.pushNamed(context, routeName!, arguments: arguments);
        } else if (onTap != null) {
          onTap!();
        }
      },
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryGreen, 
          fontWeight: FontWeight.bold, 
          fontSize: 15,
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}