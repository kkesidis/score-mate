import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/board_game.dart';
import 'screens/game_list_screen.dart';

late Isar isar;

void main() async {
  // 1. Ensure Flutter services are completely initialized before asynchronous operations
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Get the standard document directory for your OS (Linux, Android, iOS, etc.)
  final dir = await getApplicationDocumentsDirectory();

  // 3. Open the database instance with our specific BoardGame collection schema
  isar = await Isar.open(
    [BoardGameSchema],
    directory: dir.path,
  );

  runApp(const ScoreMateApp());
}

class ScoreMateApp extends StatelessWidget {
  const ScoreMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScoreMate',
      debugShowCheckedModeBanner: false,
      home: const GameListScreen(),
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF121212),       // Deep canvas background
          primary: const Color(0xFF00E676),      // Neon Emerald green accents
          secondary: const Color(0xFF263238),    // Dark Blue-Grey panels
          error: Colors.redAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        cardTheme: CardThemeData(  // FIX: Changed CardTheme to CardThemeData
          color: const Color(0xFF1E1E1E), // (or Colors.white depending on the theme chosen)
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00E676),
          foregroundColor: Color(0xFF121212),
          shape: CircleBorder(),
        ),
      ),
    );
  }
}