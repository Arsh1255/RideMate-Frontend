import 'package:flutter/material.dart';
import '../../core/colors.dart';

class StatusBanner extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;
  final IconData? icon;

  const StatusBanner({super.key, required this.text, required this.bg, required this.textColor, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          if (icon != null) Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class VerticalDashedLine extends StatelessWidget {
  final double height;
  final double thickness;
  final Color color;

  const VerticalDashedLine({super.key, required this.height, this.thickness = 3, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: SizedBox(
          width: thickness,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashHeight = 6.0;
              const dashSpace = 4.0;
              final dashCount = (constraints.maxHeight / (dashHeight + dashSpace)).floor();
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(dashCount, (_) => Container(
                  width: thickness, height: dashHeight,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                )),
              );
            },
          ),
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatItem({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}