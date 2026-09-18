import 'package:flutter/material.dart';

/// Golden Ledger Color Palette
/// Dark-first aesthetic with rich charcoal, obsidian, and imperial gold accents.
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0C0D10);
  static const Color backgroundSecondary = Color(0xFF131419);
  static const Color surface = Color(0xFF191B22);
  static const Color card = Color(0xFF20232D);
  static const Color cardElevated = Color(0xFF282C38);

  // Borders
  static const Color border = Color(0xFF2B2F3B);
  static const Color borderLight = Color(0xFF3B4050);

  // Brand / Accents - Imperial Gold & Warm Amber
  static const Color gold = Color(0xFFE5A93C);
  static const Color goldLight = Color(0xFFF7C96E);
  static const Color goldDark = Color(0xFFB88224);
  static const Color goldSurface = Color(0x22E5A93C);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF7C96E), Color(0xFFE5A93C), Color(0xFFC78B23)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF222530), Color(0xFF1B1D25)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Financial States
  static const Color income = Color(0xFF10B981);
  static const Color incomeSurface = Color(0x1F10B981);
  
  static const Color expense = Color(0xFFF43F5E);
  static const Color expenseSurface = Color(0x1FF43F5E);

  static const Color transfer = Color(0xFF38BDF8);
  static const Color transferSurface = Color(0x1F38BDF8);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0x1FF59E0B);

  // Typography
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
}
