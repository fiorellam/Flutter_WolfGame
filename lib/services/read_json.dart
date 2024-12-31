import 'dart:convert'; //Libreria de dart que ofrece funciones para codificar o decodificar datos como JSON
import 'package:flutter/services.dart' show rootBundle; //Importa librería de Flutter que permite acceder a recursos del proyecto, como archivos locales. Aquí se usa rootBundle para cargar archivos desde los assets (carpetas dentro del proyecto Flutter, como assets/).
import 'package:game_wolf/domain/user.dart';  // Asegúrate de importar la clase Person
String pathFile = "assets/users.json";

//La funcion devuelve un future<List<Player>> (Una lista de objetos Player), 
//este proceso puede tardar algun tiempo y sera completado en el futuro
Future <List<User>> loadPlayersJson() async {
  //Cargar el archivo JSON desde los assets
  //El resultado es un string (el archivo json en formato de texto y se almacena en jsonString)
  String jsonString = await rootBundle.loadString(pathFile); //Usamos await para esperar que la operacion de lectura termine antes de continuar con la ejecucion del codigo
  //Decodificar el JSON convierte el texto del archivo JSON en una lista dinamica ya que no se sabe
  //los elementos que contendra exacmatende el archivo json
  //jsonResponse es una lista de objetos que proviene del json decodificado
  List<dynamic> jsonResponse = jsonDecode(jsonString);

  //Convertir cada objeto JSON en una instancia de Player
  //.map toma cada elemento de la lista y lo transforma, utiliza la funcion fromJson y crea una instancia del Player a partir del objeto JSON
  //toList() convierte un iterable en una lista concreta de objetos Player
  List<User> players = jsonResponse.map((data) => User.fromJson(data)).toList();

  return players;
}