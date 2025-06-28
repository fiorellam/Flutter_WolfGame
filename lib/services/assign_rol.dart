import 'dart:convert'; //Libreria de dart que ofrece funciones para codificar o decodificar datos como JSON
import 'package:flutter/services.dart' show rootBundle; //Importa librería de Flutter que permite acceder a recursos del proyecto, como archivos locales. Aquí se usa rootBundle para cargar archivos desde los assets (carpetas dentro del proyecto Flutter, como assets/).
import 'package:game_wolf/domain/phase.dart';
import 'package:game_wolf/domain/phases_by_level.dart';
import 'package:game_wolf/domain/player.dart';
import 'package:game_wolf/domain/role_assignment.dart';
import 'package:game_wolf/domain/number_player_configuration.dart';
import 'package:game_wolf/services/phases_assign.dart';  // Asegúrate de importar la clase Wolves Assign

//Metodo para crear una instancia de Wolve Assign desde un Map
Future <List<NumberPlayersConfiguration>> loadNumberPlayerConfig() async {
  String pathFile = "assets/numberPlayers.json";
  //Cargar el archivo JSON desde los assets
  String jsonString = await rootBundle.loadString(pathFile); //Usamos await para esperar que la operacion de lectura termine antes de continuar con la ejecucion del codigo
  
  //Decodificar el JSON en un List de Map
  List<dynamic> jsonResponse = jsonDecode(jsonString);

  //Convertir cada objeto JSON en una instancia de Player
  List<NumberPlayersConfiguration> playersConfig = jsonResponse
      .map((data) => NumberPlayersConfiguration.fromJson(data))
      .toList();
  return playersConfig;
}

Future<int> getNumberOfWolves(int numberOfPlayers) async{
  //Cargar la configuracion desde el archivo json
  List<NumberPlayersConfiguration> configList = await loadNumberPlayerConfig();

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
Future<void> assignRolesToPlayers(List<Player> players, String level, int numLobos, int numProtectores, int numCazadores, bool lobosAncestrales) async {
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
  print('Available');
  for( var availabeRole in availableRoles){
    print('available $availabeRole');
  }

  // Determinar cuántos lobos asignar según el número de jugadores
  int numberOfPlayers = players.length;
  int numberOfWolves = numLobos != 0 ? numLobos : await getNumberOfWolves(numberOfPlayers);

  List<String> roles = availableRoles;
  if (numProtectores > 1) {
    int contador = 0;
    for(var i = 1; i < numProtectores; i++){
      contador = i;
    }
    roles.addAll(List.filled(contador, "Protector"));
  }
  if (numCazadores > 1) {
    int contador = 0;
    for(var i = 1; i < numCazadores; i++){
      contador = i;
    }
    roles.addAll(List.filled(contador, "Cazador"));
  }
  roles.addAll(List.filled(numberOfWolves, "Lobo"));
  print('Available $roles');

  // Crear la lista de roles con la cantidad correcta de lobos
  List<String> roleList = [];
  roleList.addAll(List.filled(numberOfWolves, "Lobo"));
  
  // Cantidad de jugadores que quedan que no serán lobos
  int remainingPlayers = numberOfPlayers - availableRoles.length;
  roles.addAll(List.filled(remainingPlayers, 'Granjero'));
  roles.shuffle();
  players.shuffle();
  // for(var player in players){
  //   print('avai shuffle ${player.name}');
  // }

  // Asignar los roles a los jugadores
  for (int i = 0; i < players.length; i++) {
    if(roles[i] == 'Lobo' && lobosAncestrales == true){
      players[i].role = roles[i];
      players[i].loboOriginal = true;
    } else {
      players[i].role = roles[i];
    }
  }
  // Cargar fases para el nivel seleccionado
  List<PhasesByLevel> phases = await loadPhases();
  final levelPhases = phases.firstWhere((phase) => phase.level == level);
  List<Phase> jerarquia = levelPhases.jerarquia.cast<Phase>();

  // Crear un mapa de roles a sus posiciones en las fases nocturnas
  Map<String, int> rolePriority = {};

  // Suponemos que la lista de phases en 'nightPhases' tiene un nombre que corresponde al rol
  for (int i = 0; i < jerarquia.length; i++) {
    rolePriority[jerarquia[i].name] = i;  // Asocia el nombre de la fase con su posición
  }

  // Ordenar a los jugadores según la prioridad de su rol en las fases nocturnas
  players.sort((a, b) {
    int priorityA = rolePriority[a.role] ?? 999; // Si el rol no está en el mapa, asignamos baja prioridad
    int priorityB = rolePriority[b.role] ?? 999;
    return priorityA.compareTo(priorityB); // Compara según la prioridad
  });

  // Mostrar los jugadores ordenados
  for (var player in players) {
    print('Player: ${player.name}, Role: ${player.role}, Original Lobo: ${player.loboOriginal}');
  }
}