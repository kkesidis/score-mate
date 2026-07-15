import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/board_game.dart';
import 'models/app_theme.dart';
import 'models/settings.dart';
import 'router.dart';
import 'l10n/app_localizations.dart';

final ValueNotifier<String> appLanguageNotifier = ValueNotifier('en');
late Isar isar;

void main() async {
  // 1. Ensure Flutter services are completely initialized before asynchronous operations
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Get the standard document directory for your OS (Linux, Android, iOS, etc.)
  final dir = await getApplicationDocumentsDirectory();

  // 3. Open the database instance with our specific BoardGame collection schema
  isar = await Isar.open([BoardGameSchema, AppSettingsSchema], directory: dir.path);

  final savedSettings = await isar.appSettings.where().findFirst();

  if (savedSettings != null) {
    appLanguageNotifier.value = savedSettings.languageCode;
  }

  runApp(const ScoreDenApp());
}

class ScoreDenApp extends StatelessWidget {
  const ScoreDenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguageNotifier,
      builder: (context, currentLanguageCode, child) {
        return MaterialApp.router(
          title: 'ScoreDen',
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(currentLanguageCode),
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
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
              backgroundColor: AppTheme.muted, // Dark background
              actionTextColor: AppTheme.mutedForeground,      // Color for the action button text
              disabledActionTextColor: Colors.grey,
              contentTextStyle: const TextStyle(
                color: AppTheme.mutedForeground,
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
          ),
        );
      }
    );
  }
}

Future<void> changeLanguage(String newLanguageCode) async {
  appLanguageNotifier.value = newLanguageCode;

  await isar.writeTxn(() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    
    final settings = existingSettings ?? AppSettings();
    settings.languageCode = newLanguageCode;
    
    await isar.appSettings.put(settings); 
  });
}
