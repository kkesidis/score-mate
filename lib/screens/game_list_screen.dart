import 'package:flutter/material.dart';
import '../models/board_game.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  // Temporary fake data to test our UI design
  final List<BoardGame> _mockGames = [
    BoardGame()
      ..name = 'Catan'
      ..description = 'Build settlements and trade resources.'
      ..highestScoreWins = true,
    BoardGame()
      ..name = 'Golf'
      ..description = 'Get the lowest score over 9 holes.'
      ..highestScoreWins = false,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScoreMate - Board Games'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _mockGames.isEmpty
          ? const Center(
              child: Text('No games added yet. Tap + to begin!'),
            )
          : ListView.builder(
              itemCount: _mockGames.length,
              itemBuilder: (context, index) {
                final game = _mockGames[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(game.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(game.description ?? 'No description provided.'),
                    trailing: Icon(
                      game.highestScoreWins ? Icons.arrow_upward : Icons.arrow_downward,
                      color: game.highestScoreWins ? Colors.green : Colors.blue,
                    ),
                    onTap: () {
                      // TODO: We will use this later to navigate to match sessions!
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: We will use this to show a popup form to add a game next!
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Game clicked!')),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}