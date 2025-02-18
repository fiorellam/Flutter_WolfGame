class User{
  final int id;
  final String name;
  final String lastName;
  final String phone;
  final String? numberSeat;

  User({required this.id, required this.name, required this.lastName, required this.phone, required this.numberSeat});
  // Constructor para convertir un mapa JSON en un objeto Person
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      lastName: json['lastName'],
      phone: json['phone'],
      numberSeat: json['numberSeat']
    );
  }

  // Convertir un objeto Player a un mapa JSON
    Map<String, dynamic> UserToJson() {
      return {
        'id': id,
        'name': name,
        'lastName': lastName,
        'phone': phone,
        'numberSeat': numberSeat
      };
    }
}