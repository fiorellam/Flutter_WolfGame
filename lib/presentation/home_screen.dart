import 'package:flutter/material.dart';
import 'package:game_wolf/presentation/widgets/dropdown_levels.dart';
import 'package:game_wolf/presentation/widgets/search_bar2.dart';
import 'package:game_wolf/domain/player.dart';
import 'package:game_wolf/services/read_json.dart';
class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  String _selectedValue = "Principiante"; //Valor inicial
  List<String> levelsList = ["Principiante", "Intermedio", "Avanzado", "Pro" ];
  // Lista de jugadores cargados desde el archivo JSON
  List<Player> _players = [];
  List<Player> _filteredPlayers = []; // Lista que se actualizará con los jugadores filtrados
  Set<Player> _selectedPlayers = {}; // Conjunto para almacenar los jugadores seleccionados

  @override
  void initState() {
    super.initState();
    //Cargar los jugadores desde el archivo JSON
    loadPlayersJson().then((players){
      setState(() {
        _players = players;
        _filteredPlayers = players; //Inicializa los jugadores filtrados con todos
      });
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

   // Método que maneja la selección de un item
  void _onSelectItem(Player player) {
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
      body: Column(
        children: [
          // Usamos el widget SearchBar
          SearchBar2(items: _players.map((player) => player.name).toList(), onFilter: _onFilter),
          const SizedBox(height: 20),
            Expanded(
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
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Telefono: ${player.phone}"),
                      // Text("Rol: Lobo")
                    ],
                  ),
                  subtitle:Text("Apellido: ${player.last_name}") ,
                  onTap: () => _onSelectItem(player), // Maneja la selección
                );
              },
            ),
          ),
          DropdownLevel(items: levelsList, onChanged: _handleDropdownLevelChange),   
          Text("Valor seleccionado: $_selectedValue", style: const TextStyle(fontSize: 18)),       
        ],
      ),
    );
  }
}
