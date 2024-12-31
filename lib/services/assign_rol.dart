import 'dart:convert'; //Libreria de dart que ofrece funciones para codificar o decodificar datos como JSON
import 'package:flutter/services.dart' show rootBundle; //Importa librería de Flutter que permite acceder a recursos del proyecto, como archivos locales. Aquí se usa rootBundle para cargar archivos desde los assets (carpetas dentro del proyecto Flutter, como assets/).
import 'package:game_wolf/domain/wolvesAssign.dart';  // Asegúrate de importar la clase Wolves Assign
import 'package:game_wolf/domain/user.dart';  // importar la clase Player
String pathFile = "assets/numberPayers.json";

//Metodo para crear una instancia de Wolve Assign desde un Map
Future <List<WolveAssign>> loadWolveAssign() async {
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

int getNumberOfWolves(int numberOfPlayers, List<WolveAssign> wolves) {
  // Buscar el rango adecuado de jugadores y devolver el numero de lobos
  for (var config in wolves) {
    if (numberOfPlayers >= config.minPlayers && numberOfPlayers <= config.maxPlayers){
      return config.wolves;
    }
  }
  // Regresa valor por default
  return 3;
}

// Ejemplo de cómo usarlo
Future<void> assignRolesToPlayers(List<User> players) async {
  // Cargar la configuración de asignación de roles desde el archivo JSON
  List<WolveAssign> roleAssignments = await loadWolveAssign();

  // Determinar cuántos lobos asignar según el número de jugadores
  int numberOfPlayers = players.length;
  int numberOfWolves = getNumberOfWolves(numberOfPlayers, roleAssignments);

  // Crear la lista de roles con la cantidad correcta de lobos
  List<String> roleList = [];
  roleList.addAll(List.filled(numberOfWolves, "Lobo"));
  
  // Rellenar el resto de jugadores con otros roles
  int remainingPlayers = numberOfPlayers - numberOfWolves;
  roleList.addAll(List.filled(remainingPlayers, "Aldeano"));

  // Mezclar los roles aleatoriamente
  roleList.shuffle();

  /*// Asignar los roles a los jugadores
  for (int i = 0; i < players.length; i++) {
    players[i].roles = roleList.isNotEmpty ? roleList.removeAt(0) : "Aldeano";
  }*/
}