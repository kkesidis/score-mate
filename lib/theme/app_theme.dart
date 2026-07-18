import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const List<Color> palette = [
    Color(0xFFFF6467),
    Color(0xFFFF8904),
    Color(0xFFFFBA00),
    Color(0xFFFCC800),
    Color(0xFF9AE600),
    Color(0xFF05DF72),
    Color(0xFF00D492),
    Color(0xFF00D5BE),
    Color(0xFF00D3F2),
    Color(0xFF00BCFF),
    Color(0xFF51A2FF),
    Color(0xFF7C86FF),
    Color(0xFFA684FF),
    Color(0xFFC27AFF),
    Color(0xFFED6AFF),
    Color(0xFFFB64B6),
    Color(0xFFFF637E),
  ];

  static const AppColors darkThemeColors = AppColors(
    background: Color(0xFF0D1520),
    foreground: Color(0xFFDDE8F0),
    card: Color(0xFF1A1730),
    cardForeground: Color(0xFFDDE8F0),
    popover: Color(0xFF162030),
    popoverForeground: Color(0xFFDDE8F0),
    primary: Color(0xFF4A8DB7),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF1E2F40),
    secondaryForeground: Color(0xFFDDE8F0),
    accent: Color(0xFF4BBFB8),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFC05A5A),
    destructiveForeground: Color(0xFFFFFFFF),
    muted: Color(0xFF1E2F40),
    mutedForeground: Color(0xFF6A8A9E),
    ring: Color(0xFF4A8DB7),
    switchBackground: Color(0xFF2A4060),
    border: Color(0x14FFFFFF), 
    input: Color(0xFFFFFFFF),  
    inputBackground: Color(0x12FFFFFF),
    sidebar: Color(0xFF0D1520),
    sidebarForeground: Color(0xFFDDE8F0),
    sidebarPrimary: Color(0xFF4A8DB7),
    sidebarPrimaryForeground: Color(0xFFFFFFFF),
    sidebarAccent: Color(0xFF1E2F40),
    sidebarAccentForeground: Color(0xFFDDE8F0),
    sidebarBorder: Color(0x14FFFFFF),
    sidebarRing: Color(0xFF4A8DB7),
    highestWins: Color(0x24D4A84B), 
    highestWinsForeground: Color(0xFFD4A84B), 
    lowestWins: Color(0x245B9FD6), 
    lowestWinsForeground: Color(0xFF5B9FD6), 
  );
}

ThemeData buildThemeData(AppColors colors) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme.dark(
      surface: colors.background,
      onSurface: colors.foreground,
      surfaceContainer: colors.sidebar,
      onSurfaceVariant: colors.sidebarForeground,
      primary: colors.primary,
      onPrimary: colors.primaryForeground,
      primaryContainer: colors.card,
      onPrimaryContainer: colors.cardForeground,
      primaryFixed: colors.highestWins,
      onPrimaryFixed: colors.highestWinsForeground,
      secondary: colors.secondary,
      onSecondary: colors.secondaryForeground,
      secondaryContainer: colors.muted,
      onSecondaryContainer: colors.mutedForeground,
      secondaryFixed: colors.lowestWins,
      onSecondaryFixed: colors.lowestWinsForeground,
      tertiary: colors.accent,
      onTertiary: colors.accentForeground,
      tertiaryContainer: colors.sidebarAccent,
      onTertiaryContainer: colors.sidebarAccentForeground,
      error: colors.destructive,
      onError: colors.destructiveForeground,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colors.foreground,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.border,
          width: 1.0,
        )
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.accent,
      foregroundColor: colors.accentForeground,
      shape: const CircleBorder(),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStateProperty.all(
          BorderSide(color: colors.border, width: 1.0),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.secondary;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.secondaryForeground;
          }
        
          return colors.foreground;
        }),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.inputBackground,
      labelStyle: TextStyle(
        color: colors.primary,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(
        color: colors.primary,
        fontSize: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.border, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.border, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      
        borderSide: BorderSide(color: colors.secondary, width: 1.5), 
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.border, 
      thickness: 1.0,
      space: 1.0,
    ),
    tooltipTheme: TooltipThemeData(
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colors.background.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      textStyle: TextStyle(
        color: colors.foreground,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating, 
      backgroundColor: colors.popover,
      actionTextColor: colors.popoverForeground,     
      disabledActionTextColor: Colors.grey,
      contentTextStyle: TextStyle(
        color: colors.popoverForeground,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      insetPadding: const EdgeInsets.all(12),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: colors.sidebar,
      endShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          bottomLeft: Radius.circular(32.0),
        ),
      ),
      elevation: 16.0,
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: colors.sidebar,
      indicatorColor: colors.sidebarPrimary,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: colors.sidebarPrimaryForeground,
          );
        }
        return TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: colors.sidebarForeground,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: colors.sidebarPrimaryForeground,
            size: 24,
          );
        }
        return IconThemeData(
          color: colors.sidebarForeground,
          size: 24,
        );
      }),
    ),
  );
}
