import 'package:flutter/material.dart';
import 'package:game_wolf/database/database_helper.dart';
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
  //esto es para modificar las variables desde la funcion _adminPartida
  int _numLobos = 0;
  int _numProtectores = 0;
  int _numCazadores = 0;
  //Constante
  static const List<String> levelsList = ["Principiante", "Intermedio", "Avanzado", "Pro" ];
  String _selectedValue = levelsList.first; //Valor inicial
  // Lista de jugadores cargados desde el archivo JSON
  List<User> _players = [];
  List<User> _filteredPlayers = []; // Lista que se actualizará con los jugadores filtrados
  //En Dart, un Set es una colección no ordenada de elementos únicos. A diferencia de una List, que permite elementos duplicados, 
  //un Set garantiza que cada elemento se aparezca solo una vez. Por lo tanto, si intentas agregar un elemento que ya existe en un Set, no se agregará de nuevo.
  Set<User> _selectedPlayers = {}; // Conjunto para almacenar los jugadores seleccionados
  bool _allSelected = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  //Navegar a nueva pantalla
  void _startGameScreen() async{
    if(_selectedPlayers.length < 7){
      _showMinimumPlayersDialog();
      return;
    }
    //Llamar funcion que convierte lista de User a Player
    List<Player> gamePlayers = convertUsersToPlayers(_selectedPlayers.toList());
    //Asignar roles a los jugadores
    await assignRolesToPlayers(gamePlayers, _selectedValue, _numLobos, _numProtectores, _numCazadores);

    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => GameScreen(selectedPlayers: gamePlayers, level: _selectedValue, ))
    );
  }

  // Método para mostrar un AlertDialog cuando hay menos de 7 jugadores
void _showMinimumPlayersDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Jugadores insuficientes"),
        content: const Text("Debes seleccionar al menos 7 jugadores para iniciar la partida. en el nivel principiante"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar el diálogo
            },
            child: const Text("Aceptar"),
          ),
        ],
      );
    },
  );
}

  // Agregar nuevo usuario mediante un modal
  void _showDialogCreateUser() {
    // Controladores para el formulario
    final TextEditingController nameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController numberSeatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Jugador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: numberSeatController,
                decoration: const InputDecoration(labelText: 'Asiento'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el modal sin guardar
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed:  () async {
                // Validar y agregar el nuevo jugador
                if (nameController.text.isNotEmpty &&
                    // lastNameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty 
                    // numberSeatController.text.isNotEmpty
                    ) {
                  // setState(()  {
                    final newUser = User(
                      id: 0,
                      name: nameController.text,
                      lastName: lastNameController.text,
                      phone: phoneController.text,
                      numberSeat: numberSeatController.text
                    );
                    // _players.add(newUser);
                    final db = await _databaseHelper.getDatabase();
                    bool userAdded = await _databaseHelper.insertUser(db, newUser);

                    if(userAdded){
                      //si el usuario fue insertado correctamente
                    //RECARGAR LA LISTA DE JUGADORES DESDE LA BASE DE DATOS
                      await _loadPlayers();
                      setState((){});
                      Navigator.of(context).pop(); // Cerrar el modal
                    } else {
                      // Si el usuario ya existe, mostrar un mensaje
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Este usuario ya existe.')),
                      );
                    }

                    // Actualiza _filteredPlayers dinámicamente solo si contiene filtros
                  if (_filteredPlayers.length != _players.length) {
                    _filteredPlayers = List.from(_players);
                  }
                  // });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, completa todos los campos.')),
                  );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _showDialogEditUser(User user){
    final TextEditingController nameController = TextEditingController(text: user.name);
    final TextEditingController lastNameController = TextEditingController(text: user.lastName);
    final TextEditingController phoneController = TextEditingController(text: user.phone);
    final TextEditingController numberSeatController = TextEditingController(text: user.numberSeat);

    showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Jugador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Apellido')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(controller: numberSeatController, decoration: const InputDecoration(labelText: 'Asiento')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final db = await _databaseHelper.getDatabase();
                final updatedUser = User(
                  id: user.id,
                  name: nameController.text,
                  lastName: lastNameController.text,
                  phone: phoneController.text,
                  numberSeat: numberSeatController.text,
                );

                await _databaseHelper.updateUser(db, updatedUser);

                setState(() {
                  int indexUser = _players.indexWhere((us) => us.id == user.id);
                  if(indexUser != -1 ){
                    _players[indexUser] = updatedUser;
                  }
                  // También actualizar la lista filtrada si se está usando
                  int filteredIndex = _filteredPlayers.indexWhere((u) => u.id == user.id);
                    if (filteredIndex != -1) {
                      _filteredPlayers[filteredIndex] = updatedUser;
                    }
                  });
                await _loadPlayers(); // Recargar lista
                Navigator.of(context).pop();
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        );
      }
    );
  }

  void _deleteUser(User user) async {
    final db = await _databaseHelper.getDatabase();
    await _databaseHelper.deleteUser(db, user);
    await _loadPlayers(); // Recargar lista
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

  // Cargar jugadores desde el JSON
  Future<void> _loadPlayers() async{
    final db = await _databaseHelper.getDatabase();
    final usersData = await _databaseHelper.getUsers(db);

     // Guardar los IDs de los jugadores seleccionados
    final selectedIds = _selectedPlayers.map((p) => p.id).toSet();
    setState(() {
      _players = usersData.map((userData){
        return User(
          id: userData['id'],
          name: userData['name'],
          lastName: userData['lastName'],
          phone: userData['phone'],
          numberSeat: userData['numberSeat'],
        );
      }).toList();
      _filteredPlayers = _players;//Inicializa los jugadores filtrados
      // Restaurar la selección de los jugadores previos
    _selectedPlayers = _players.where((p) => selectedIds.contains(p.id)).toSet();
    });
  }
  // Future<void> _loadPlayers() async{
  //   final players = await loadPlayersJson();
  //   setState(() {
  //     _players = players;
  //     _filteredPlayers = players;//Inicializa los jugadores filtrados
  //   });
  // }
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

  //metodo para seleccionar y deseleccionar
  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedPlayers.clear();
      } else {
        _selectedPlayers.addAll(_filteredPlayers);
      }
      _allSelected = !_allSelected;
    });
  }

  //mavegar a create screen
  void _adminPartida(){
    //controladores para el formulario
    final TextEditingController loboController = TextEditingController();
    final TextEditingController protectorController = TextEditingController();
    final TextEditingController cazadorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Administrator de Partida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: loboController,
                decoration: InputDecoration(labelText: 'Lobos $_numLobos')
              ),
              TextField(
                controller: protectorController,
                decoration: InputDecoration(labelText: 'Protectores $_numProtectores')
              ),
              TextField(
                controller: cazadorController,
                decoration: InputDecoration(labelText: 'Cazadores $_numCazadores')
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); //cerrar el modal sin guardar
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _numLobos = int.tryParse(loboController.text) ?? 0;
                  _numProtectores = int.tryParse(protectorController.text) ?? 0;
                  _numCazadores = int.tryParse(cazadorController.text) ?? 0;
                });
                Navigator.of(context).pop(); //cerrar modal
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Buscar Jugadores'),
        actions: [
          IconButton(
            icon: Icon(_allSelected ? Icons.deselect : Icons.select_all),
            onPressed: _toggleSelectAll,
            tooltip: _allSelected ? "Deseleccionar todos" : "Seleccionar todos",
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0), //16 px en todos los lados
        child: Column(
          children: [
            Row(
              children: [
                //SearchBar Ocupa el mayor espacio
                Expanded(
                  // Usamos el widget SearchBar
                  child: SearchBar2(items: _players.map((player) => player.name).toList(), onFilter: _onFilter),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _showDialogCreateUser,
                  style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0), // Ajusta el redondeo aquí
                        ),
                  ), 
                  child: const Text("Agregar Jugador"),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => {},
                  style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0), // Ajusta el redondeo aquí
                        ),
                  ),
                  child: const Text("Guardar Jugadores"),),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _toggleSelectAll,
                  child: Text(_allSelected ? "Deseleccionar todos" : "Seleccionar todos"),
                ),
              ],

            ),
            const SizedBox(height: 10),
            _buildPlayerListView(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jugadores seleccionados ${_selectedPlayers.length}', 
                  style: TextStyle(
                    fontSize: 18.0, 
                    
                    // Cambia este valor al tamaño que desees
                  ),
                ),
                DropdownLevel(items: levelsList, onChanged: _handleDropdownLevelChange),
                Text('Lobos: $_numLobos | Protector: $_numProtectores | Cazador: $_numCazadores',
                  style: TextStyle(
                    fontSize: 18.0, //cambia este valor al tamaño que deseas
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4.0),
                  child: FilledButton(
                    onPressed: _adminPartida,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0), // Ajusta el redondeo aquí
                      ),
                    ), 
                    child: const Text("Editar Partida"),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4.0),
                  child: FilledButton(
                    onPressed: _startGameScreen,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0), // Ajusta el redondeo aquí
                      ),
                    ), 
                    child: const Text("Iniciar Partida"),
                  ),
                ),
              ]
            )     
          ],
        ),
      ),
    );
  }
//Separar la lista de jugadores filtradoes en un metodo
  Widget _buildPlayerListView(){
    if(_players.isEmpty){
      return Expanded(
        child: Center (
          child: Text(
            'Aun no hay jugadores registrados.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemCount: _filteredPlayers.length, // Muestra los elementos filtrados
        itemBuilder: (context, index) {
          final player = _filteredPlayers[index];
          final isSelected = _selectedPlayers.contains(player); // Verifica si el item está seleccionado
          return Card(
            child: ListTile(
              leading: Icon (
                isSelected ? Icons.check_circle : Icons.check_circle_outline, // Muestra el icono dependiendo de la selección
                color: isSelected ? Colors.green : Colors.grey,// Cambia el color según el estado de selección,
              ),
              title: Text('${player.name} ${player.lastName}      Tel: ${player.phone}      Asiento: ${player.numberSeat}',
                style: new TextStyle(
                  fontSize: 20.0,
                )),
              // subtitle: Text('Tel: ${player.phone}',
              //   style: new TextStyle(
              //     fontSize: 20.0,
              //   )),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showDialogEditUser(player),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(player),
                  ),
                ],
              ),
              onTap: () => _onSelectPlayer(player), // Maneja la selección
            ),
          );
        },
      ),
    );
  }
}
