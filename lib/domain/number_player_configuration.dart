class NumberPlayersConfiguration{
  final int minPlayers;
  final int maxPlayers;
  final int wolves;

  NumberPlayersConfiguration({required this.minPlayers, required this.maxPlayers, required this.wolves});
  // Constructor para convertir un mapa JSON en un objeto Person
  factory NumberPlayersConfiguration.fromJson(Map<String, dynamic> json) {
    return NumberPlayersConfiguration(
      minPlayers: json['min_players'],
      maxPlayers: json['max_players'],
      wolves: json['wolves'],
    );
  }
}