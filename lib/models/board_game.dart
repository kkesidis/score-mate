import 'package:isar/isar.dart';

part 'board_game.g.dart';

@collection
class BoardGame {
  Id id = Isar.autoIncrement;

  late String name;
  String? description;
  bool highestScoreWins = true;

  List<MatchSession> sessions = [];
}

@embedded
class MatchSession {
  String? name;
  DateTime? dateTime;

  List<PlayerSession> players = [];
}

@embedded
class PlayerSession {
  String? playerName;
  List<ScoreEntry> scores = [];
}

@embedded
class ScoreEntry {
  int? value;
  String? description;
}