import 'package:flutter/material.dart';
import '../core/colors.dart';

class IconGradientButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final double height;

  const IconGradientButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.height = 52,
  });

  @override
  State<IconGradientButton> createState() => _IconGradientButtonState();
}

class _IconGradientButtonState extends State<IconGradientButton> {
  double scale = 1.0;

  void _onTapDown(_) => setState(() => scale = 0.96);
  void _onTapUp(_) => setState(() => scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => scale = 1.0),

      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryBlue,
                AppColors.primaryGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}