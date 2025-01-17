import 'package:game_wolf/domain/player.dart';

abstract class GameLevel {
  String get levelName;

  Future<List<String>> getRoles(); // Obtiene roles para este nivel
  Future<List<String>> getPhases(); // Obtiene fases para este nivel

  void executeDayPhase(List<Player> players);
  void executeNightPhase(List<Player> players);
}