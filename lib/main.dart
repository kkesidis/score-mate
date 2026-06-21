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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const GameListScreen(),
    );
  }
}