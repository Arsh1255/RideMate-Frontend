import 'package:flutter/material.dart';
import 'theme_mode_notifier.dart';

class AppColors {
  static bool get isDark => themeModeNotifier.value == ThemeMode.dark;

  // CORE PALETTE
  static const primaryBlue = Color(0xFF00BFFF);
  static const primaryGreen = Color(0xFF39D35F);
  
  static Color get background => isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
  
  // Semantic mapping: 'white' is surface, 'black' is on-surface
  static Color get white => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get black => isDark ? const Color(0xFFE0E0E0) : const Color(0xFF000000);
  
  static const transparent = Colors.transparent;

  // TEXT
  static Color get textPrimary => isDark ? const Color(0xFFE0E0E0) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFFA0A0A0) : const Color(0xFF64748B);
  static Color get textBold => isDark ? const Color(0xFFCCCCCC) : const Color(0xFF4B5563);
  static Color get infoText => isDark ? const Color(0xFF888888) : const Color(0xFF606D83);

  // BORDERS & LINES
  static Color get border => isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0);
  static const borderBlue = Color(0xFF04C0F2);

  // STATUS & SEMANTIC
  static const error = Color(0xFFEF4444);
  static Color get successBg => isDark ? const Color(0xFF1B3B2B) : const Color(0xFFDCFCE7); // Muted dark green
  
  static Color get pendingBg => isDark ? const Color(0xFF3B2B1B) : const Color(0xFFFEF3C7); // Muted dark yellow
  static Color get pendingText => isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E);
  
  static Color get warningBg => isDark ? const Color(0xFF3B251B) : const Color(0xFFFFF7ED); // Muted dark orange
  static Color get warningText => isDark ? const Color(0xFFFB923C) : const Color(0xFFF97316);
  
  static Color get removedText => isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF8B58);

  // BOXES & CARDS
  static Color get infoBlue => isDark ? const Color(0x3D00BFFF) : const Color(0x7AACEDFF); // Lower opacity in dark
  static Color get infoLight => isDark ? const Color(0x1F00BFFF) : const Color(0x3D19C5FF);
  
  // COMPONENT SPECIFIC
  static Color get avatarBg => isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0);
  
  // LEADERBOARD MEDALS
  static const medalGold = Color(0xFFFACC15);
  static const medalSilver = Color(0xFF9CA3AF);
  static const medalBronze = Color(0xFFB45309);
  
  static Color get goldHighlight => isDark ? const Color(0xFF2D2A10) : const Color(0xFFFEFCE8);
  static Color get silverHighlight => isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6);
  static Color get bronzeHighlight => isDark ? const Color(0xFF2D1E10) : const Color(0xFFFFFBEB);
}