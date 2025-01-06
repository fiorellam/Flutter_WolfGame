class Role{
  final String name;

  Role({required this.name});
   // Constructor para convertir un mapa JSON en un objeto Role
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      name: json['name'],
    );
  }
}