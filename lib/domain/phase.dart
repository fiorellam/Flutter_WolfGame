class Phase{
  final String name;

  Phase({required this.name});

  factory Phase.fromJson(Map<String, dynamic> json){
    return Phase(name: json['name']);
  }
}