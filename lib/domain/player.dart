class Player{
  final int id;
  final String name;
  final String lastName;
  final String phone;
  String role;
  String? secondaryRol;
  String? state;
  int curado = 0;

  Player({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    required this.role,
    this.state,
    this.secondaryRol,
    this.curado = 0
  });

  //Convertir un mapa JSON en un objeto Player
  factory Player.fromJson(Map<String, dynamic> json){
    return Player(
      id: json['id'],
      name: json['name'],
      lastName: json['lastName'],
      phone: json['phone'],
      role: json['role'], 
      secondaryRol: json['secondaryRol'] as String?,
      state: json['state'],
      curado: json['curado']
    );
  }
}