import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:game_wolf/domain/player.dart';  // Asegúrate de importar la clase Person
String pathFile = "assets/players.json";

//La funcion devuelve un future<List<Player>> (Una lista de objetos Player), 
//este proceso puede tardar algun tiempo y sera completado en el futuro
Future <List<Player>> loadPlayersJson() async {
  //Cargar el archivo JSON desde los assets
  String jsonString = await rootBundle.loadString(pathFile); //Usamos await para esperar que la operacion de lectura termine antes de continuar con la ejecucion del codigo

  //Decodificar el JSON
  List<dynamic> jsonResponse = jsonDecode(jsonString);
  print('JSON RESPONSE ${jsonResponse}');

  //Convertir cada objeto JSON en una instancia de Player
  List<Player> players = jsonResponse.map((data) => Player.fromJson(data)).toList();

  return players;
}