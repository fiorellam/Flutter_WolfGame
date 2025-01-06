import 'package:flutter/material.dart';
import 'package:game_wolf/domain/player.dart';
import 'package:game_wolf/domain/user_player_mapper.dart';
import 'package:game_wolf/presentation/game_screen.dart';
import 'package:game_wolf/presentation/widgets/dropdown_levels.dart';
import 'package:game_wolf/presentation/widgets/search_bar2.dart';
import 'package:game_wolf/domain/user.dart';
import 'package:game_wolf/services/read_json.dart';
import 'package:game_wolf/services/assign_rol.dart';
class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  //Constante
  static const List<String> levelsList = ["Principiante", "Intermedio", "Avanzado", "Pro" ];
  String _selectedValue = levelsList.first; //Valor inicial
  // Lista de jugadores cargados desde el archivo JSON
  List<User> _players = [];
  List<User> _filteredPlayers = []; // Lista que se actualizará con los jugadores filtrados
  //En Dart, un Set es una colección no ordenada de elementos únicos. A diferencia de una List, que permite elementos duplicados, 
  //un Set garantiza que cada elemento se aparezca solo una vez. Por lo tanto, si intentas agregar un elemento que ya existe en un Set, no se agregará de nuevo.
  Set<User> _selectedPlayers = {}; // Conjunto para almacenar los jugadores seleccionados

  //Navegar a nueva pantalla
  void _startGameScreen() async{
    //Llamar funcion que convierte lista de User a Player
    List<Player> gamePlayers = convertUsersToPlayers(_selectedPlayers.toList());
    //Asignar roles a los jugadores
    await assignRolesToPlayers(gamePlayers, _selectedValue);

    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => GameScreen(selectedPlayers: gamePlayers, level: _selectedValue, ))
    );
  }

  List<Player> convertUsersToPlayers(List<User> users){
    return users.map((user){
      return UserPlayerMapper.userToPlayer(user);
    }).toList();
  }
  //Metodo que se llama una vez cuando se crea el estado de la pantalla
  @override
  void initState() {
    super.initState();
    //Cargar los jugadores desde el archivo JSON
    _loadPlayers();
  }

  //Cargar jugadores desde el JSON
  Future<void> _loadPlayers() async{
    final players = await loadPlayersJson();
    setState(() {
      _players = players;
      _filteredPlayers = players;//Inicializa los jugadores filtrados
    });
  }
  //Función que será llamada cuando cambie el valor del dropdown
  void _handleDropdownLevelChange(String value){
    setState(() {
      _selectedValue = value; //Actualizamos el valor del dropdown
    });
  }

  // Método que maneja los resultados filtrados
  void _onFilter(List<String> filteredItems) {
  setState(() {
    _filteredPlayers = _players
      .where((player) => filteredItems.any((filter) => player.name.toLowerCase().contains(filter.toLowerCase())))
      .toList();
  });
  }

   // Método que maneja la selección de un jugador
  void _onSelectPlayer(User player) {
    setState(() {
      if (_selectedPlayers.contains(player)) {
        _selectedPlayers.remove(player); // Si ya está seleccionado, lo deseleccionamos
      } else {
        _selectedPlayers.add(player); // Si no está seleccionado, lo seleccionamos
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Jugadores'),
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0), //16 px en todos los lados
        child: Column(
          children: [
            // Usamos el widget SearchBar
            SearchBar2(items: _players.map((player) => player.name).toList(), onFilter: _onFilter),
            const SizedBox(height: 20),
            _buildPlayerListView(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownLevel(items: levelsList, onChanged: _handleDropdownLevelChange),   
                Text("Valor seleccionado: $_selectedValue", style: const TextStyle(fontSize: 18)),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(onPressed: _startGameScreen, child: const Text("Iniciar Partida")),
                )
              ]
            )     
          ],
        ),
      ),
    );
  }
//Separar la lista de jugadores filtradoes en un metodo
  Widget _buildPlayerListView(){
    return Expanded(
      child: ListView.builder(
        itemCount: _filteredPlayers.length, // Muestra los elementos filtrados
        itemBuilder: (context, index) {
          final player = _filteredPlayers[index];
          final isSelected = _selectedPlayers.contains(player); // Verifica si el item está seleccionado
          return ListTile(
            leading: Icon (
              isSelected ? Icons.check_circle : Icons.check_circle_outline, // Muestra el icono dependiendo de la selección
              color: isSelected ? Colors.green : Colors.grey,
            ), // Cambia el color según el estado de selección,
            title: Text(player.name),
            subtitle:Text(player.lastName) ,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Telefono: ${player.phone}"),
                // Text("Rol: Lobo")
              ],
            ),
            onTap: () => _onSelectPlayer(player), // Maneja la selección
          );
        },
      ),
    );
  }
}
