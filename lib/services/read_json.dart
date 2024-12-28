import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:game_wolf/domain/player.dart';  // Asegúrate de importar la clase Person

Future <List<Player>> loadPlayersJson() async {
  //Cargar el archivo JSON desde los assets
  String jsonString = await rootBundle.loadString('assets/player.dart');

  //Decodificar el JSON
  List<dynamic> jsonResponse = jsonDecode(jsonString);

  //Convertir cada objeto JSON en una instancia de Player
  List<Player> players = jsonResponse.map((data) => Player.fromJson(data)).toList();

  return players;
}