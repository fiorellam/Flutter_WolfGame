import 'dart:convert'; //Libreria de dart que ofrece funciones para codificar o decodificar datos como JSON
import 'package:flutter/services.dart' show rootBundle; //Importa librería de Flutter que permite acceder a recursos del proyecto, como archivos locales. Aquí se usa rootBundle para cargar archivos desde los assets (carpetas dentro del proyecto Flutter, como assets/).
import 'package:game_wolf/domain/player.dart';
import 'package:game_wolf/domain/role_assignment.dart';
import 'package:game_wolf/domain/wolves_assign.dart';  // Asegúrate de importar la clase Wolves Assign

//Metodo para crear una instancia de Wolve Assign desde un Map
Future <List<WolveAssign>> loadWolveAssign() async {
  String pathFile = "assets/numberPlayers.json";
  //Cargar el archivo JSON desde los assets
  String jsonString = await rootBundle.loadString(pathFile); //Usamos await para esperar que la operacion de lectura termine antes de continuar con la ejecucion del codigo
  
  //Decodificar el JSON en un List de Map
  List<dynamic> jsonResponse = jsonDecode(jsonString);

  //Convertir cada objeto JSON en una instancia de Player
  List<WolveAssign> wolves = jsonResponse
      .map((data) => WolveAssign.fromJson(data))
      .toList();

  return wolves;
}

Future<int> getNumberOfWolves(int numberOfPlayers) async{
  //Cargar la configuracion desde el archivo json
  List<WolveAssign> configList = await loadWolveAssign();

  //Buscar la configuracion adecuada segun el numero de jugadores
  for(var config in configList){
    if(numberOfPlayers >= config.minPlayers && numberOfPlayers <= config.maxPlayers){
      return config.wolves;
    }
  }

  //Si no se encuentra una configuracion, devolvemos un valor predeterminado
  return 3;
}
//Funcion que carga los roles del archivo JSON
Future<List<RoleAssignment>> loadRolesFromJson() async{
  String pathFile = "assets/rol.json";
  String jsonString = await rootBundle.loadString(pathFile);
  List<dynamic> jsonResponse = jsonDecode(jsonString);
  return jsonResponse.map((data) => RoleAssignment.fromJson(data)).toList();
}

// Ejemplo de cómo usarlo
Future<void> assignRolesToPlayers(List<Player> players, String level) async {
  // Cargar los roles desde el archivo JSON
  List<RoleAssignment> rolesByLevel = await loadRolesFromJson();

  // Buscar el objeto RoleAssignment correspondiente al nivel
  RoleAssignment? selectedLevel = rolesByLevel.firstWhere(
    (roleAssignment) => roleAssignment.level == level,
    orElse: () => RoleAssignment(level: "Default", roles: [])
  );

  if (selectedLevel.roles.isEmpty) {
    print("NIVEL NO VALIDO: $level");
    return;
  }

  // Crear la lista de roles para los jugadores
  List<String> availableRoles = selectedLevel.roles.map((role) => role.name).toList();

  // Determinar cuántos lobos asignar según el número de jugadores
  int numberOfPlayers = players.length;
  int numberOfWolves = await getNumberOfWolves(numberOfPlayers);

  // Crear la lista de roles con la cantidad correcta de lobos
  List<String> roleList = [];
  roleList.addAll(List.filled(numberOfWolves, "Lobo"));
  
  // Cantidad de jugadores que quedan que no serán lobos
  int remainingPlayers = numberOfPlayers - numberOfWolves;
  
  // Crear una lista de roles para los jugadores restantes
  List<String> additionalRoles = _getRolesForLevel(availableRoles, remainingPlayers);
  roleList.addAll(additionalRoles);

  // Asegurarse de que solo el granjero y el lobo se repitan
  Map<String, int> roleCount = {}; // Para contar cuántas veces se asigna cada rol
  List<String> validRoleList = [];

  for (var role in roleList) {
    if (role == "Lobo" || role == "Granjero") {
      // Solo los roles "Lobo" y "Granjero" pueden aparecer más de una vez
      validRoleList.add(role);
    } else {
      // Los otros roles solo pueden aparecer una vez
      if (!roleCount.containsKey(role)) {
        validRoleList.add(role);
        roleCount[role] = 1; // Marcar este rol como asignado
      }
    }
  }

  // Mezclar los roles aleatoriamente
  validRoleList.shuffle();

  // Asignar los roles a los jugadores
  for (int i = 0; i < players.length; i++) {
    players[i].role = validRoleList.isNotEmpty ? validRoleList.removeAt(0) : "Granjero";
  }
}

// Método que devuelve los roles disponibles según el nivel y los jugadores restantes
List<String> _getRolesForLevel(List<String> availableRoles, int remainingPlayers) {
  List<String> roles = [];

  // Asignar roles hasta que se llenen los jugadores restantes
  int numberOfRoles = availableRoles.length;
  for (int i = 0; i < remainingPlayers; i++) {
    roles.add(availableRoles[i % numberOfRoles]); // Repite los roles si hay más jugadores que roles
  }

  return roles;
}