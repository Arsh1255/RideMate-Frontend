import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/colors.dart';
import '../core/theme_mode_notifier.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RideMate",
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Find Your Ride buddy!",
                    style: TextStyle(
                      fontSize: 12, 
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _tile(
              context, 
              icon: LucideIcons.house, 
              title: "Home", 
              route: '/home',
            ),
            const SizedBox(height: 8),
            _tile(
              context,
              icon: LucideIcons.layoutDashboard,
              title: "Dashboard",
              route: '/dashboard',
            ),
            const Spacer(),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return SwitchListTile(
                  title: const Text(
                    "Dark Mode",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  secondary: Icon(
                    isDark ? LucideIcons.moon : LucideIcons.sun,
                    color: isDark ? AppColors.primaryGreen : AppColors.textSecondary,
                  ),
                  value: isDark,
                  onChanged: (value) {
                    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                  },
                  activeColor: AppColors.primaryGreen,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isActive = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon, 
        color: isActive ? AppColors.primaryBlue : AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.primaryBlue : AppColors.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      tileColor: isActive ? AppColors.primaryBlue.withValues(alpha: 0.08) : AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context); 
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}