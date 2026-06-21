import 'package:flutter/material.dart';

void main() {
  runApp(const ScoreMateApp());
}

class ScoreMateApp extends StatelessWidget {
  const ScoreMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Welcome to ScoreMate!'),
        ),
      ),
    );
  }
}