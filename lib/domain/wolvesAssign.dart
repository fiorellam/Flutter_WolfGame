class WolveAssign{
  final int minPlayers;
  final int maxPlayers;
  final int wolves;

  WolveAssign({required this.minPlayers, required this.maxPlayers, required this.wolves});
  // Constructor para convertir un mapa JSON en un objeto Person
  factory WolveAssign.fromJson(Map<String, dynamic> json) {
    return WolveAssign(
      minPlayers: json['min_players'],
      maxPlayers: json['max_players'],
      wolves: json['wolves'],
    );
  }
}