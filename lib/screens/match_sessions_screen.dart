import 'package:flutter/material.dart';
import '../main.dart'; // Imports our global 'isar' instance
import '../models/board_game.dart';
import '../models/app_theme.dart';
import '../components/stylized_card.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';

class MatchSessionsScreen extends StatefulWidget {
  final int gameId;

  const MatchSessionsScreen({super.key, required this.gameId});

  @override
  State<MatchSessionsScreen> createState() => _MatchSessionsScreenState();
}

class _MatchSessionsScreenState extends State<MatchSessionsScreen> {
  BoardGame? _game;
  StreamSubscription? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _loadGameData();
    _listenToDatabaseChanges();
  }

  void _loadGameData() async {
    final game = await isar.boardGames.get(widget.gameId);
    if (mounted) {
      setState(() {
        _game = game;
      });
    }
  }

  // Set up a listener so if the parent game updates, this screen reflects it instantly
  void _listenToDatabaseChanges() {
    _dbSubscription = isar.boardGames.watchObjectLazy(widget.gameId).listen((_) async {
      final updatedGame = await isar.boardGames.get(widget.gameId);
      if (updatedGame != null && mounted) {
        setState(() {
          _game = updatedGame;
        });
      }
    });
  }

  @override
  void dispose() {
    _dbSubscription?.cancel(); // <-- Stop listening when screen is destroyed
    super.dispose();
  }

  void _showSessionDialog({int? actualIndex}) {
    final nameController = TextEditingController();
    final isEditing = actualIndex != null;

    if (isEditing) {
      final existingSession = _game!.sessions[actualIndex];
      nameController.text = existingSession.name ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to resize when keyboards push up
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    16.0, // Keyboard safety
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? AppLocalizations.of(context)!.renameSession : AppLocalizations.of(context)!.newSession,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    autofocus: true,
                    controller: nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.sessionNameLabel,
                      hintText: isEditing
                          ? null
                          : AppLocalizations.of(context)!.sessionNameHint(_game!.sessions.length + 1),
                    ),
                  ),

                  const SizedBox(height: 24),

                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing:
                        8.0, // Horizontal gap between buttons when side-by-side
                    overflowSpacing:
                        8.0, // Vertical gap between buttons if they drop/stack vertically!
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.primaryForeground,
                        ),
                        onPressed: () async {
                          final textInput = nameController.text.trim();

                          // Edit guard: don't let them clear out an existing name to empty string
                          if (isEditing && textInput.isEmpty) return;

                          final updatedSessions = _game!.sessions
                              .toList();

                          if (isEditing) {
                            // 2A. EXECUTE TRANSACTION EDIT UPDATE ROUTINE
                            updatedSessions[actualIndex].name = textInput;
                          } else {
                            // 2B. EXECUTE TRANSACTION CREATE INSERTION ROUTINE
                            final nextMatchNumber =
                                _game!.sessions.length + 1;
                            final sessionName = textInput.isEmpty
                                ? AppLocalizations.of(context)!.indexedSession(nextMatchNumber)
                                : textInput;

                            final newSession = MatchSession()
                              ..name = sessionName
                              ..dateTime = DateTime.now();

                            updatedSessions.add(newSession);
                          }

                          // 3. PERSIST THE SESSION LIST ARRAY STATE CHUNK
                          _game!.sessions = updatedSessions;
                          await isar.writeTxn(() async {
                            await isar.boardGames.put(_game!);
                          });

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(isEditing ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.add),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int actualIndex, String sessionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteSessionTitle),
          content: Text(
            AppLocalizations.of(context)!.deleteSessionDescription(sessionName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.destructive,
                foregroundColor: AppTheme.destructiveForeground,
              ),
              onPressed: () {
                _deleteSession(actualIndex);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );
  }

  // 3. ACTUAL ISAR DELETE TRANSACTION
  void _deleteSession(int actualIndex) async {
    final updatedSessions = _game!.sessions.toList();
    updatedSessions.removeAt(actualIndex); // Pull it out of the array slot
    _game!.sessions = updatedSessions;

    await isar.writeTxn(() async {
      await isar.boardGames.put(_game!);
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.sessionRemoved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context)!.couldNotFindGame),
        ),
      );
    }

    // Read the list from our dynamically updated local game variable
    final sessions = _game!.sessions;

    final highlightColor = _game?.colorValue != null ? Color(_game!.colorValue!) : AppTheme.palette.first;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.sessionsTitle),
            const SizedBox(height: 2), // Tiny spacer between lines
            Text(
              _game!.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ), // Fades out the subtitle nicely
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.newSession),
                onPressed: () {
                  _showSessionDialog();
                },
              ),
            ),
          ),
          Expanded(
            child: sessions.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.noSessionsYet))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    // REVERSE ORDER LOGIC:
                    // Instead of counting 0, 1, 2... from the front,
                    // we count backwards from the last item in the list.
                    final reversedIndex = sessions.length - 1 - index;
                    final session = sessions[reversedIndex];

                    // Use the true list placement index for the default naming fallback
                    final sessionName =
                        session.name ?? AppLocalizations.of(context)!.indexedSession(reversedIndex + 1);

                    final sessionDate = session.dateTime != null
                        ? '${session.dateTime!.day}/${session.dateTime!.month}/${session.dateTime!.year}'
                        : AppLocalizations.of(context)!.notAvailable;

                    final sessionPlayers = session.players ?? [];

                    String winnerText = AppLocalizations.of(context)!.noWinnerYet;
                    if (sessionPlayers.isNotEmpty) {
                      final highestScoreWins = _game!.highestScoreWins;

                      // Create a map matching each player to their calculated total score
                      final playerScores = <PlayerSession, int>{};
                      for (var player in sessionPlayers) {
                        final total = player.scores.fold(
                          0,
                          (sum, item) => sum + (item.value ?? 0),
                        );
                        playerScores[player] = total;
                      }

                      // Find the winning score value based on game settings
                      int winningScore = playerScores.values.first;
                      for (var score in playerScores.values) {
                        if (highestScoreWins) {
                          if (score > winningScore) winningScore = score;
                        } else {
                          if (score < winningScore) winningScore = score;
                        }
                      }

                      // Collect all players who hit that exact winning score target
                      final winners = playerScores.entries
                          .where((entry) => entry.value == winningScore)
                          .map((entry) => entry.key.playerName ?? AppLocalizations.of(context)!.notAvailable)
                          .toList();

                      // Format the output string depending on if it's a solo victory or a tie!
                      if (winners.length > 1) {
                        winnerText = '${AppLocalizations.of(context)!.tie}: ${winners.join(', ')} ($winningScore)';
                      } else {
                        winnerText = '${AppLocalizations.of(context)!.winner}: ${winners.first} ($winningScore)';
                      }
                    }

                    return StylizedCard(
                      shadowColor: highlightColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(
                              sessionName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              winnerText,
                              style: const TextStyle(color: AppTheme.mutedForeground),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: highlightColor,
                                  ),
                                  tooltip: AppLocalizations.of(context)!.renameSession,
                                  onPressed: () {
                                    _showSessionDialog(actualIndex: reversedIndex);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.destructive,
                                  ),
                                  tooltip: AppLocalizations.of(context)!.deleteSession,
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(
                                      reversedIndex,
                                      sessionName,
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              context.go('/home/${_game!.id}/sessions/$reversedIndex');
                            },
                          ),

                          const SizedBox(height: 4),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    // Match your standard chip background filter: rgba(255, 255, 255, 0.07)
                                    color: const Color(0x12FFFFFF), 
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min, // Wraps container tightly around the contents
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 13, // Slightly adjusted down for balanced layout scale
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        sessionDate, // Outputs just the raw dynamic date
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    // Match your standard chip background filter: rgba(255, 255, 255, 0.07)
                                    color: const Color(0x12FFFFFF), 
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min, // Wraps container tightly around the content
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 13, // Balanced layout scale matching the date chip
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '${sessionPlayers.length} ',
                                              style: const TextStyle(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.w600, // Highlights the count number matching your first chip design
                                              ),
                                            ),
                                            TextSpan(
                                              text: AppLocalizations.of(context)!.players,
                                            ),
                                          ],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
