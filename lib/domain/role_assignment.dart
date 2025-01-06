import 'package:game_wolf/domain/role.dart';

class RoleAssignment {
  final String level;
  final List<Role> roles;

  RoleAssignment({required this.level, required this.roles});

  factory RoleAssignment.fromJson(Map<String, dynamic> json){
    var list = json['roles'] as List;
    List<Role> rolesList = list.map((role) => Role.fromJson(role)).toList();
    return RoleAssignment(level: json['level'], roles: rolesList);
  }
}