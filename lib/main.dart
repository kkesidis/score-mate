import 'package:flutter/material.dart';
import 'screens/game_list_screen.dart'; 

void main() {
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
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const GameListScreen(),
    );
  }
}