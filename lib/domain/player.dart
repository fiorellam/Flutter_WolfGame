class Player{
  final String name;
  final String last_name;
  final String phone;

  Player({required this.name, required this.last_name, required this.phone});
  // Constructor para convertir un mapa JSON en un objeto Person
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      last_name: json['last_name'],
      phone: json['phone'],
    );
  }
}