class Player{
  final int id;
  final String name;
  final String lastName;
  final String phone;
  final String role;
  final String state;

  Player({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    required this.role,
    required this.state
  });

  //Convertir un mapa JSON en un objeto Player
  factory Player.fromJson(Map<String, dynamic> json){
    return Player(
      id: json['id'],
      name: json['name'],
      lastName: json['lastName'],
      phone: json['phone'],
      role: json['role'], 
      state: json['state']
    );
  }
}