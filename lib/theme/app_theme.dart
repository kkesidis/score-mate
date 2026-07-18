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

final ThemeData appThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppTheme.background,
  colorScheme: const ColorScheme.dark(
    primary: AppTheme.primary,
    error: AppTheme.destructive,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppTheme.foreground,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppTheme.card, // (or Colors.white depending on the theme chosen)
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(
        color: AppTheme.border,
        width: 1.0,
      )
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppTheme.accent,
    foregroundColor: AppTheme.accentForeground,
    shape: CircleBorder(),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      // MaterialStateProperty (or WidgetStateProperty in newer Flutter versions) 
      // ensures the border stays consistent across all button interactions
      side: WidgetStateProperty.all(
        const BorderSide(color: AppTheme.border, width: 1.0),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTheme.secondary; // Active selected fill color
        }
        return Colors.transparent; // Resting background fill color
      }),

      // 3. Text & Icon Colors (Foreground)
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTheme.secondaryForeground; // Active contrast label color
        }
        // Resting label color with a clean opacity layer
        return AppTheme.foreground;
      }),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppTheme.inputBackground, // Your custom background color
    
    // The base styling rules for the fonts/labels inside the input
    labelStyle: const TextStyle(
      color: AppTheme.primary,
      fontSize: 14,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

    hintStyle: const TextStyle(
      color: AppTheme.primary,
      fontSize: 12,
    ),

    // 1. Default resting border state
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.border, width: 1.0),
    ),

    // 2. Explicitly enabled border (displays when textfield is editable but not clicked)
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.border, width: 1.0),
    ),

    // 3. Focused border (displays when the user is actively typing inside it)
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      // We bump the color or width slightly on focus for great UX interaction feedback
      borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5), 
    ),

    // 4. Error state border adjustments
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppTheme.border, 
    thickness: 1.0,
    space: 1.0,
  ),
  tooltipTheme: TooltipThemeData(
    preferBelow: false, // Prevents finger/thumb from blocking the popup
    triggerMode: TooltipTriggerMode.tap, // Instant tap response on mobile
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: AppTheme.background.withValues(alpha: 0.2),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    
    // Styling the text inside the global tooltip
    textStyle: const TextStyle(
      color: AppTheme.foreground,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating, 
    backgroundColor: AppTheme.popover, // Dark background
    actionTextColor: AppTheme.popoverForeground,      // Color for the action button text
    disabledActionTextColor: Colors.grey,
    contentTextStyle: const TextStyle(
      color: AppTheme.popoverForeground,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 6,
    insetPadding: const EdgeInsets.all(12),
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: AppTheme.sidebar,
    endShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(32.0),
        bottomLeft: Radius.circular(32.0),
      ),
    ),
    elevation: 16.0,
  ),
  navigationDrawerTheme: NavigationDrawerThemeData(
    backgroundColor: AppTheme.sidebar,
    indicatorColor: AppTheme.sidebarPrimary,
    indicatorShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppTheme.sidebarPrimaryForeground, // Active text color
        );
      }
      return const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
        color: AppTheme.sidebarForeground, // Inactive text color
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(
          color: AppTheme.sidebarPrimaryForeground, // Active icon color
          size: 24,
        );
      }
      return const IconThemeData(
        color: AppTheme.sidebarForeground, // Inactive icon color
        size: 24,
      );
    }),
  ),
);