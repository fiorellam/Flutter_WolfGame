class User{
  final int id;
  final String name;
  final String lastName;
  final String phone;

  User({required this.id, required this.name, required this.lastName, required this.phone});
  // Constructor para convertir un mapa JSON en un objeto Person
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      lastName: json['lastName'],
      phone: json['phone'],
    );
  }
}