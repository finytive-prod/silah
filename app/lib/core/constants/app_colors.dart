import 'package:flutter/material.dart';

/// App color tokens adhering to Material 3 light theme
/// Spec: Islamic Emerald Green & Warm Gold accents, high contrast for elderly users.
class AppColors {
  // Primary
  static const Color primary = Color(0xFF0D5C3A); // Deep Islamic Emerald Green
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE8F5E9); // Mint highlight container
  static const Color onPrimaryContainer = Color(0xFF0A3D27);

  // Secondary & Accents
  static const Color secondary = Color(0xFFD4AF37); // Warm Gold / Brass
  static const Color onSecondary = Color(0xFF000000);
  static const Color secondaryContainer = Color(0xFFFFF8E1);
  static const Color onSecondaryContainer = Color(0xFF5D4037);

  // Surface & Background
  static const Color surface = Color(0xFFFAFAFA); // Soft glare-free off-white
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color outline = Color(0xFFE0E0E0);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF596066);
  static const Color textMuted = Color(0xFF757575);

  // Status & Alerts
  static const Color success = Color(0xFF2E7D32); // Sandha Paid
  static const Color warning = Color(0xFFED6C02); // Sandha Pending
  static const Color emergency = Color(0xFFBA1A1A); // Janazah / Urgent alerts
}
