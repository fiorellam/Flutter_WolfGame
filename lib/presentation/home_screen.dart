import 'package:flutter/material.dart';
import 'package:game_wolf/database/database_helper.dart';
import 'package:game_wolf/domain/player.dart';
import 'package:game_wolf/domain/user_player_mapper.dart';
import 'package:game_wolf/presentation/game_screen.dart';
import 'package:game_wolf/presentation/widgets/dropdown_levels.dart';
import 'package:game_wolf/presentation/widgets/search_bar2.dart';
import 'package:game_wolf/domain/user.dart';
import 'package:game_wolf/services/assign_rol.dart';
class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>{
  //esto es para modificar las variables desde la funcion _adminPartida
  int _numLobos = 0;
  int _numProtectores = 0;
  int _numCazadores = 0;
  //Constante
  static const List<String> levelsList = ["Principiante", "Intermedio", "Avanzado", "Pro" ];
  String _selectedValue = ''; //Valor inicial
  // Lista de jugadores cargados desde el archivo JSON
  List<User> _users = [];
  List<User> _filteredUsers = []; // Lista que se actualizará con los jugadores filtrados
  //En Dart, un Set es una colección no ordenada de elementos únicos. A diferencia de una List, que permite elementos duplicados, 
  //un Set garantiza que cada elemento se aparezca solo una vez. Por lo tanto, si intentas agregar un elemento que ya existe en un Set, no se agregará de nuevo.
  Set<User> _selectedUsers = {}; // Conjunto para almacenar los jugadores seleccionados
  bool _allSelected = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Color? warningColor = Colors.orange[300];
  Color? errorColor = Colors.red[300];
  Color? successColor = Colors.green[500];

  bool _isAssigningSeats = false;
  int _nextSeatNumber = 1;
  final Map<int, String> _tempAssignedSeats = {}; // user.id → seat number temporal
  
  //Navegar a nueva pantalla
  void _startGameScreen() async{
    if(!_validateUniquePhonesAndSeats()){
      return;
    }
    // Verificar que se haya seleccionado un nivel
    if (_selectedValue.isEmpty) {
      _showMessageDialog("Nivel no seleccionado","Debes seleccionar un nivel para iniciar la partida.");
      return; // Si no se seleccionó un nivel, no se procede
    }
    if(_selectedUsers.length < 7 && _selectedValue == levelsList.first){
      _showMessageDialog("Jugadores Insuficientes","Debes seleccionar al menos 7 jugadores para iniciar la partida en el nivel ${levelsList.first}");
      return;
    } else if (_selectedUsers.length < 10 && _selectedValue == levelsList[1]){
      _showMessageDialog("Jugadores Insuficientes","Debes seleccionar al menos 10 jugadores para iniciar la partida en el nivel ${levelsList[1]}");
      return;
    } else if (_selectedUsers.length < 13  && _selectedValue == levelsList[2]){
      _showMessageDialog("Jugadores Insuficientes","Debes seleccionar al menos 10 jugadores para iniciar la partida en el nivel ${levelsList[1]}");
      return;
    } else if (_selectedUsers.length < 16  && _selectedValue == levelsList[3]){
      _showMessageDialog("Jugadores Insuficientes","Debes seleccionar al menos 10 jugadores para iniciar la partida en el nivel ${levelsList[1]}");
      return;
    }
    //Llamar funcion que convierte lista de User a Player
    List<Player> gamePlayers = convertUsersToPlayers(_selectedUsers.toList());
    //Asignar roles a los jugadores
    await assignRolesToPlayers(gamePlayers, _selectedValue, _numLobos, _numProtectores, _numCazadores);

    // Verificar si el widget aún está montado antes de usar context
    // Después de un await, como en:
    // await assignRolesToPlayers(...)
    // el widget puede haber sido desmontado (por ejemplo, si el usuario salió de la pantalla). Entonces, si haces algo como Navigator.push(context, ...) después de eso, podrías estar usando un BuildContext que ya no es válido, y eso causa bugs sutiles (crashes, mal comportamiento).
    if (!mounted) return;

    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => GameScreen(selectedPlayers: gamePlayers, level: _selectedValue, ))
    );
  }

  //Verificar si el asiento esta ocupado
  Future<bool> _isSeatOccupied(String seat, int userId) async{
    seat = seat.trim();
    bool seatExists;
    //si se deja el asiento vacio, no pasa nada
    if(seat.isEmpty || seat == '0' || seat == ' ' || seat == ''){
      return false;
    }
    //Si se envia el user Id
    if(userId != 0){
      //Se verifica si el asiento esta ocupado y se excluye el usuario que se envia como parametro de la lista de jugadores
      seatExists = _users.any((player) => player.numberSeat?.trim() == seat.trim() && player.id != userId);
    } else {
      //Aqui solo se verifica si el asiento esta ocupado por algun usuario
      seatExists = _users.any((player) => player.numberSeat?.trim() == seat.trim());
    }

    if (seatExists) {
      showCustomSnackBar(context, 'Este número de asiento ya está ocupado.', warningColor!);
      return true; // El asiento ya está ocupado
    }
    return false; //El asiento no está ocupado
  }

  void _removeSeatsDB(List<User> users) async {
    return await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text("Deseas eliminar los asientos de los jugadores?"),
        content: Text('¿Estás seguro que deseas eliminar los asientos?'),
        actions: [
          TextButton(
                onPressed: () => Navigator.of(context).pop(false), // No salir
                child: Text("Cancelar"),
              ),
          TextButton(
            onPressed: () async{
              final db = await _databaseHelper.getDatabase();
              for(var user in users){
                if(user.numberSeat != '' || user.numberSeat != ' ' || user.numberSeat!.trim().isNotEmpty){
                  user.numberSeat = '';
                  await _databaseHelper.updateUser(db, user);
                }
              }
              await _loadPlayers();
              _nextSeatNumber = 1;

              if (mounted) {
                Navigator.of(context).pop(false);
                showCustomSnackBar(context, 'Asientos eliminados correctamente.', successColor!);
              }
            }, // Salir
            child: Text("Eliminar asientos"),
          ),
        ],
      )
    );    
    
  }

  // Agregar nuevo usuario mediante un modal
  void _showDialogCreateUser() {
    // Controladores para el formulario
    final nameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final numberSeatController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Jugador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Apellido')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
              TextField(controller: numberSeatController, decoration: const InputDecoration(labelText: 'Asiento')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.of(context).pop();},
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed:  () async {
                // Validar y agregar el nuevo jugador
                bool isValid = await _validatePlayer(nameController, lastNameController, phoneController, numberSeatController);
                if(isValid){
                  bool seatOccupied = await _isSeatOccupied(numberSeatController.text, 0);
                  if(seatOccupied){
                    return;
                  }
                  bool isInserted = await _insertUserDB(nameController.text, lastNameController.text, phoneController.text, numberSeatController.text);
                  if (isInserted) {
                    Navigator.of(context).pop(); // Cerrar el diálogo al agregar el jugador
                  }
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
    final nameController = TextEditingController(text: user.name);
    final lastNameController = TextEditingController(text: user.lastName);
    final phoneController = TextEditingController(text: user.phone);
    final numberSeatController = TextEditingController(text: user.numberSeat);

    showDialog(
      context: context, 
      barrierDismissible: false,
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
                bool isValid = await _validatePlayer(nameController, lastNameController, phoneController, numberSeatController);
                if(isValid){
                  //Compara el asiento nuevo con el anterior
                  // String newSeat = numberSeatController.text.trim();
                  // String? currentSeat = user.numberSeat?.trim();
                  bool isSeatChanged = numberSeatController.text.trim() != user.numberSeat?.trim();
                  if(isSeatChanged){
                    // Si el asiento ha cambiado, validamos si está ocupado
                    if(await _isSeatOccupied(numberSeatController.text.trim(), user.id) ){
                      return; // Si el asiento está ocupado, no hacemos nada más
                    }
                  }
                  bool isUpdated = await _updateUserDB(user, nameController, lastNameController, phoneController, numberSeatController);
                  if(isUpdated){
                    Navigator.of(context).pop();
                  }                  
                }
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        );
      }
    );
  }

  Future<bool> _insertUserDB (String name, String lastName, String phone, String seat) async{
    //Usuario que se va a insertar
    final newUser = User(
      id: 0,
      name: name,
      lastName: lastName,
      phone: phone,
      numberSeat: seat
    );
    
    //Inserción en la base de datos
    final db = await _databaseHelper.getDatabase();
    bool userAdded = await _databaseHelper.insertUser(db, newUser);

    if (userAdded) {
      await _loadPlayers(); //Recarga de jugadores
      if (!mounted) return false; //  Verifica si el widget aún está activo
      showCustomSnackBar(context, 'Jugador agregado con éxito.', successColor!);
      return true;
    } else {
      if (!mounted) return false; //  Verifica si el widget aún está activo
      showCustomSnackBar(context, 'Este usuario ya existe.', warningColor!);
      return false;
    }
  }

  Future<bool> _updateUserDB (User user, TextEditingController nameController, TextEditingController lastNameController, TextEditingController phoneController, TextEditingController numberSeatController) async{
    final updatedUser = User(
      id: user.id,
      name: nameController.text,
      lastName: lastNameController.text,
      phone: phoneController.text,
      numberSeat: numberSeatController.text.trim(),
    );

    //Update a la base de datos
    final db = await _databaseHelper.getDatabase();
    bool isUpdated = await _databaseHelper.updateUser(db, updatedUser);

    if(isUpdated){
      setState(() {
        int indexUser = _users.indexWhere((us) => us.id == user.id);
        if(indexUser != -1 ){
          _users[indexUser] = updatedUser;
        }
        // También actualizar la lista filtrada si se está usando
        int filteredIndex = _filteredUsers.indexWhere((u) => u.id == user.id);
          if (filteredIndex != -1) {
            _filteredUsers[filteredIndex] = updatedUser;
          }
        });
      await _loadPlayers(); // Recargar lista
      if (!mounted) return false; //  Verifica si el widget aún está activo
      showCustomSnackBar(context, 'Jugador actualizado con éxito.', successColor!);
      return true;
    } else {
      if (!mounted) return false;
      showCustomSnackBar(context, 'No se pudo actualizar al jugador.', errorColor!);
      return false;
    }
  }

  void _deleteUser(User user) async {
      final db = await _databaseHelper.getDatabase();
      await _databaseHelper.deleteUser(db, user);
      await _loadPlayers(); // Recargar lista
  }

  Future<bool> _validatePlayer(TextEditingController name, TextEditingController lastName, TextEditingController phone, TextEditingController seat) async{
    //Validar campos
    if (name.text.isEmpty || lastName.text.isEmpty ) {
      showCustomSnackBar(context,'Nombre y apellido son obligatorios', warningColor!);
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text ('Nombre y apellido son obligatorios')));
      return false;
    }   
    return true; // Esto indica que la validación fue exitosa
  }

  bool _validateUniquePhonesAndSeats(){
    final Map<String, List<User>> phoneMap = {};
    final seats = <String>{};

    for (var user in _selectedUsers) {
      final phone = user.phone.trim();
      final seat = user.numberSeat?.trim();
      if (phone.isEmpty) continue;

      if(seat != null && seat.trim().isNotEmpty){
        if(seats.contains(seat)){
          showCustomSnackBar(context, 'De los jugadores seleccionados 2 tienen el mismo asiento', errorColor!);
          return false;
        } else{
          seats.add(seat);
        }
      } else {
        _showMessageDialog('Asiento faltante', "El jugador ${user.name} ${user.lastName} no tiene número de asiento.");
        return false;
      }
      if (!phoneMap.containsKey(phone)) {
        phoneMap[phone] = [];
      }
      phoneMap[phone]!.add(user);

    }
    final duplicates = phoneMap.entries.where((e) => e.value.length > 1).toList();
  
    if (duplicates.isNotEmpty) {
      for (var entry in duplicates) {
        final players = entry.value.map((u) => '${u.name} ${u.lastName}').join(', ');
        _showMessageDialog('Teléfono duplicado', 'Teléfono: ${entry.key} está repetido por: $players');
      }
      return false;
    }
    return true;
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
    final selectedIds = _selectedUsers.map((p) => p.id).toSet();
    setState(() {
      _users = usersData.map((userData){
        return User(
          id: userData['id'],
          name: userData['name'],
          lastName: userData['lastName'],
          phone: userData['phone'],
          numberSeat: userData['numberSeat'],
        );
      }).toList();
      _filteredUsers = _users;//Inicializa los jugadores filtrados
      // Restaurar la selección de los jugadores previos
    _selectedUsers = _users.where((p) => selectedIds.contains(p.id)).toSet();
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
    _filteredUsers = _users
      .where((player) => filteredItems.any((filter) => player.name.toLowerCase().contains(filter.toLowerCase())))
      .toList();
  });
  }

   // Método que maneja la selección de un jugador
  void _onSelectPlayer(User player) {
    setState(() {
      if (_isAssigningSeats) {
        // Verifica si el jugador aún no tiene un asiento asignado temporalmente.
        if (!_tempAssignedSeats.containsKey(player.id)) {
           //Asigna un número de asiento temporal al jugador.
          _tempAssignedSeats[player.id] = _nextSeatNumber.toString();
          // Cambia visualmente el asiento del jugador para que se vea en la interfaz.
          player.numberSeat = _nextSeatNumber.toString(); // visual
          _nextSeatNumber++;
        } else {
          _tempAssignedSeats.remove(player.id);
          player.numberSeat = ''; // quitar visualmente
        }
      } else {
        if (_selectedUsers.contains(player)) {
          _selectedUsers.remove(player);
        } else {
          _selectedUsers.add(player);
        }
      }
    });
  }

  //metodo para seleccionar y deseleccionar
  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedUsers.clear();
      } else {
        _selectedUsers.addAll(_filteredUsers);
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
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Administrador de Partida'),
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
   // Método para mostrar un AlertDialog cuando hay menos de 7 jugadores
  void _showMessageDialog(String titleDialog, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titleDialog),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () { Navigator.of(context).pop();},
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void showCustomSnackBar(BuildContext context, String message, Color backgroundColor) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20), 
      duration: const Duration(seconds: 3),
    ),
  );
}

void _confirmAssignSeatsToDB() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Guardar asignaciones?'),
      content: const Text('¿Deseas guardar los números de asiento asignados?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final db = await _databaseHelper.getDatabase();
    for (var entry in _tempAssignedSeats.entries) {
      final userId = entry.key;
      final seat = entry.value;
      final user = _users.firstWhere((u) => u.id == userId);
      user.numberSeat = seat;
      await _databaseHelper.updateUser(db, user);
    }

    _tempAssignedSeats.clear();
    _nextSeatNumber = 1;
    _isAssigningSeats = false;

    await _loadPlayers();
    if (mounted) {
      showCustomSnackBar(context, 'Asientos asignados correctamente', successColor!);
    }
  } else {
    for (var entry in _tempAssignedSeats.entries) {
      final userId = entry.key;
      final user = _users.firstWhere((u) => u.id == userId);
      user.numberSeat = ''; // O null, según como manejes los asientos vacíos
    }

    _tempAssignedSeats.clear();
    _nextSeatNumber = 1;
    _isAssigningSeats = false;

    setState(() {}); // Redibuja la interfaz
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Buscar Jugadores'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: 
            FilledButton.icon(
              onPressed: () => _removeSeatsDB(_users), 
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              label: const Text('Eliminar asientos', style: TextStyle(fontSize: 17),),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black12,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            )
          )
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
                  child: SearchBar2(items: _users.map((player) => player.name).toList(), onFilter: _onFilter),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _showDialogCreateUser,
                  style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0), // Ajusta el redondeo aquí
                        ),
                  ), 
                  child: const Icon(Icons.add),
                  // child: const Text("Agregar Jugador"),
                ),
                const SizedBox(width: 10),
                DropdownLevel(items: levelsList, onChanged: _handleDropdownLevelChange),

                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(_allSelected ? Icons.deselect : Icons.select_all),
                  onPressed: _toggleSelectAll,
                  tooltip: _allSelected ? "Deseleccionar todos" : "Seleccionar todos",
                ),
                // FilledButton(
                //   onPressed: _toggleSelectAll,
                //   child: Text(_allSelected ? "Deseleccionar todos" : "Seleccionar todos"),
                // ),
              ],

            ),
            const SizedBox(height: 10),
            _buildPlayerListView(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton(
                  onPressed: (){
                    setState((){
                      _isAssigningSeats = !_isAssigningSeats;
                      if (!_isAssigningSeats) { 
                        for (var entry in _tempAssignedSeats.entries) {
                          final userId = entry.key;
                          final user = _users.firstWhere((u) => u.id == userId);
                          user.numberSeat = ''; // O null, según como manejes los asientos vacíos
                        }
                        _tempAssignedSeats.clear();
                        _nextSeatNumber = 1;
                      }
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _isAssigningSeats ?  Colors.blue: Colors.purple[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0), // Ajusta el redondeo aquí
                    ),
                  ),
                  child: Text(_isAssigningSeats ? 'Cancelar asignación' : 'Asignar asientos'),
                ),
                if (_isAssigningSeats && _tempAssignedSeats.isNotEmpty)
                  FilledButton(
                    onPressed: _confirmAssignSeatsToDB,
                    child: const Text('Confirmar asignación'),
                ),
                Text('Jugadores seleccionados ${_selectedUsers.length}', 
                  style: TextStyle(
                    fontSize: 18.0, // Cambia este valor al tamaño que desees
                  ),
                ),
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
                      foregroundColor: Colors.white,
                      backgroundColor: Color.fromARGB(147, 49, 220, 98),
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
    if(_users.isEmpty){
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
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 2.8,
        children: _filteredUsers.map((player) {
          final isSelected = _selectedUsers.contains(player);
          return Card(
            margin: const EdgeInsets.all(2),
            child: InkWell(
              onTap: () => _onSelectPlayer(player),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Columna 1: Icono check
                    Icon(
                      isSelected ? Icons.check_circle : Icons.check_circle_outline,
                      color: isSelected ? Colors.green : Colors.grey,
                      size: 30,
                    ),
                    const SizedBox(width: 8),
                    // Columna 2: Info del jugador
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${player.name} ${player.lastName}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tel: ${player.phone}',
                            style: const TextStyle(fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Asiento: ${player.numberSeat}',
                            style: const TextStyle(fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Columna 3: Iconos editar y borrar
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                          onPressed: () => _showDialogEditUser(player),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                          onPressed: () => _deleteUser(player),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
