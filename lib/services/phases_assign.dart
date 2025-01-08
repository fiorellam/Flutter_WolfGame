import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:game_wolf/domain/phases_by_level.dart';

Future<List<PhasesByLevel>> loadPhases() async{
  String pathFile = "assets/phasesByLevel.json";

  // Cargar el archivo JSON desde los assets
  String jsonString = await rootBundle.loadString(pathFile);

  // Decodificar el JSON en una lista de mapas
  List<dynamic> jsonResponse = jsonDecode(jsonString);

  // Convertir cada objeto JSON en una instancia de Level
  List<PhasesByLevel> phases = jsonResponse.map((data) => PhasesByLevel.fromJson(data)).toList();

  return phases;

}