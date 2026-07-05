import 'package:flutter/material.dart';

class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // Core Colors
  static const Color background = Color(0xFF0D1520);
  static const Color foreground = Color(0xFFDDE8F0);
  
  // Cards & Popovers
  static const Color card = Color(0xFF1A1730);
  static const Color cardForeground = Color(0xFFDDE8F0);
  static const Color popover = Color(0xFF162030);
  static const Color popoverForeground = Color(0xFFDDE8F0);

  // Brand / Brand Intent Action Colors
  static const Color primary = Color(0xFF4A8DB7);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF1E2F40);
  static const Color secondaryForeground = Color(0xFFDDE8F0);
  static const Color accent = Color(0xFF4BBFB8);
  static const Color accentForeground = Color(0xFFFFFFFF);
  static const Color destructive = Color(0xFFC05A5A);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  // UI Element Accents & States
  static const Color muted = Color(0xFF1E2F40);
  static const Color mutedForeground = Color(0xFF6A8A9E);
  static const Color ring = Color(0xFF4A8DB7);
  static const Color switchBackground = Color(0xFF2A4060);

  // Dynamic Opacity Borders & Inputs (rgba mappings)
  static const Color border = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color input = Color(0xFFFFFFFF);  // rgba(255, 255, 255, 0.07)
  static final Color inputBackground = const Color(0xFFFFFFFF).withValues(alpha: 0.07);

  // Typography Constants
  static const FontWeight fontWeightMedium = FontWeight.w600; // 600
  static const FontWeight fontWeightNormal = FontWeight.w400; // 400

  // Layout Properties
  static const double radiusValue = 16.0; // 1rem calculated as 16px default base
  static final BorderRadius radius = BorderRadius.circular(radiusValue);

  // Specialized Color Palettes
  static const Color color1 = Color(0xFF5B9FD6);
  static const Color color2 = Color(0xFF4BBFB8);
  static const Color color3 = Color(0xFF7B8FC4);
  static const Color color4 = Color(0xFFC47A5B);
  static const Color color5 = Color(0xFF6AAB7C);

  // Sidebar Layout Theme Profile
  static const Color sidebar = Color(0xFF0D1520);
  static const Color sidebarForeground = Color(0xFFDDE8F0);
  static const Color sidebarPrimary = Color(0xFF4A8DB7);
  static const Color sidebarPrimaryForeground = Color(0xFFFFFFFF);
  static const Color sidebarAccent = Color(0xFF1E2F40);
  static const Color sidebarAccentForeground = Color(0xFFDDE8F0);
  static final Color sidebarBorder = const Color(0xFFFFFFFF).withValues(alpha: 0.08);
  static const Color sidebarRing = Color(0xFF4A8DB7);

  // Highest Wins Styling
  static const Color highestWins = Color(0x24D4A84B); // rgba(212, 168, 75, 0.14)
  static const Color highestWinsForeground = Color(0xFFD4A84B); // rgb(212, 168, 75)

  // Lowest Wins Styling
  static const Color lowestWins = Color(0x245B9FD6); // rgba(91, 159, 214, 0.14)
  static const Color lowestWinsForeground = Color(0xFF5B9FD6); // rgb(91, 159, 214)
}