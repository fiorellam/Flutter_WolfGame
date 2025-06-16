import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:game_wolf/domain/phase.dart';
import 'package:game_wolf/domain/phases_by_level.dart';
import 'package:game_wolf/domain/player.dart';
import 'package:game_wolf/services/phases_assign.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:flutter_sms/flutter_sms.dart';

class GameScreen extends StatefulWidget {
  final List<Player> selectedPlayers;
  final String level;

  const GameScreen({super.key, required this.selectedPlayers, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int convertToWolf = 0;
  int potions = 0;
  bool potionSheriff = true;
  bool potionAyudante = true;
  bool potionPueblo = true;
  int potionUse = 0;
  bool isDay = true;
  String gameState = "Lobos Turno";
  String nextStatePhase = ''; 
  List<Phase> dayPhases = [];
  List<Phase> nightPhases = [];
  int currentPhaseIndex = 0;
  late Player? lastDeathByWolf;
  bool hasSheriffBeenSelected = false; //Controla si el sheriff ha sido seleccionado
  bool hasCupidoBeenSelected = false; //Controla si cupido ya paso su turno
  List<String> recordActions = ['DIA 1 ☀️'];
  int dayCounter = 1;
  int nightCounter = 0;
  int curanderoTimesBeenSaved = 0;
  int subirImpuesto = -1;
  int bajarImpuesto = -1;
  bool afectaBrujaVidente = false;
  bool pocionOscura = false;
  bool pocion = false;
  //declarar una sola vez
  final sizeProtector = 0;
  final sizeCazador = 0;
  //String _selectedValue; //Valor inicial

  @override
  void initState(){
    super.initState();
    _initializePhases();
  }

  Future<void> _initializePhases() async{
    List<PhasesByLevel> phases = await loadPhases();

    //Filtrar fases por nivel seleccionado
    final levelPhases = phases.firstWhere((phase) => phase.level == widget.level);
    convertToWolf = (widget.selectedPlayers.length <= 8) ? 1 : (widget.selectedPlayers.length <= 15) ? 2 : 3;
    potions = (widget.selectedPlayers.length <= 9) ? 1 : (widget.selectedPlayers.length <= 20) ? 3 : 2;

    setState(() {
      dayPhases = levelPhases.dia.cast<Phase>();
      nightPhases = levelPhases.noche.cast<Phase>();
      gameState = isDay ? dayPhases[0].name : nightPhases[0].name; // Inicializar el juego
      nextStatePhase = dayPhases[1].name;
    });
    
    _turnInfo(levelPhases);
    //Turno para Cupido
    /*if (isDay && levelPhases.level != 'Principiante' && !hasCupidoBeenSelected) {
      _turnCupido();
      hasCupidoBeenSelected = true;
    }*/
  }

  void _updatePotions(){
    Player? selectedPlayer;
    Player? selectedPlayer2;

    try{
      selectedPlayer = widget.selectedPlayers.firstWhere(
        (player) => (player.secondaryRol == 'Sheriff' && player.state == 'Muerto') || (player.secondaryRol == 'Ayudante' && player.state == 'Muerto'));
    } catch (e){
      selectedPlayer = lastDeathByWolf;
    }

    //aqui verificamos si efectivamente existe
    if(selectedPlayer?.phoneFlechado != null){
      try {
        selectedPlayer2 = widget.selectedPlayers.firstWhere(
          (player) => (player.phone == selectedPlayer?.phoneFlechado));
      } catch (e){
        selectedPlayer2 = null;
      }
    }

    if (selectedPlayer?.secondaryRol == 'Sheriff'){
      setState((){
        potionSheriff = false;
        selectedPlayer?.state = 'Vivo';
        _generateRecord('El Sheriff ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName} uso la poción para salvarse');
      });
    } else {
      if (selectedPlayer?.secondaryRol == 'Ayudante'){
        setState((){
          potionAyudante = false;
          selectedPlayer?.state = 'Vivo';
          _generateRecord('El ayudante ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName} uso la poción para salvarse');
        });
      } else {
        if(selectedPlayer2 != null){
          setState((){
            potionPueblo = false;
            selectedPlayer?.state = 'Vivo';
            selectedPlayer2?.state = 'Vivo';
            _generateRecord('El pueblo decidió salvar por medio de la poción a ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName} y además salvan a ${selectedPlayer2?.role} - ${selectedPlayer2?.name} que esta enamorado');
          });
        } else {
          setState((){
            potionPueblo = false;
            selectedPlayer?.state = 'Vivo';
            _generateRecord('El pueblo decidió salvar por medio de la poción a ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName}');
          });
        }
      }
    }
  }

  void _updatePotionAlcalde(){
    Player? selectedPlayer;

    try{
      selectedPlayer = widget.selectedPlayers.firstWhere(
        (player) => (player.secondaryRol == 'Alcalde' && player.state == 'Muerto'));
    } catch (e){
      selectedPlayer = lastDeathByWolf;
    }

    if (pocion == true){
      setState((){
        pocion = false;
        selectedPlayer?.state = 'Vivo';
        _generateRecord('${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName} uso la poción para salvarse');
      });
    } else {
      if (pocionOscura == true){
        setState((){
          pocionOscura = false;
          selectedPlayer?.state = 'Vivo';
          _generateRecord('Alcalde uso la poción oscura ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName} para salvarse');
          _elegirRole();
        });
      }
    }
  }
  
  void _elegirRole() {
    Player? selectedPlayer;  // Jugador que esta relacionado con el anterior

    try{
      selectedPlayer = widget.selectedPlayers.firstWhere(
        (player) => (player.role == 'Alcalde'));
    } catch (e){
      selectedPlayer = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Alcalde murió"),
            ]
          ),
          content: Text('Puede escoger entre estos 2 roles'),
          actions: [
            TextButton(
              onPressed: () {
                setState((){
                  selectedPlayer?.role = 'Lobo Solitario';
                  _generateRecord('Alcalde ${selectedPlayer?.numberSeat} - ${selectedPlayer?.name} ${selectedPlayer?.lastName} escogió el nuevo Role -> Lobo Solitario');
                  Navigator.of(context).pop();
                });
              },
              child: const Text("Lobo Solitario")),
            TextButton(
              onPressed: () {
                _generateRecord('Alcalde ${selectedPlayer?.numberSeat} - ${selectedPlayer?.name} ${selectedPlayer?.lastName} escogió el nuevo Role -> Leproso');
                selectedPlayer?.role = 'Leproso';
                Navigator.of(context).pop();
              },
              child: const Text("Leproso"),
            ),
          ],
        );
      },
    );
  }

  void _updateGameState(List<Phase> currentPhases) {
     // Actualizar el estado del juego (fase actual)
      gameState = isDay ? dayPhases[currentPhaseIndex].name : nightPhases[currentPhaseIndex].name;
      // Obtener la siguiente fase
      if (currentPhaseIndex < currentPhases.length - 1) {
        nextStatePhase = isDay ? dayPhases[currentPhaseIndex + 1].name : nightPhases[currentPhaseIndex + 1].name;
      } else {
        // Si estamos en la última fase de un ciclo (día o noche), la siguiente fase será la del ciclo opuesto (día o noche)
        nextStatePhase = isDay ? nightPhases[0].name : dayPhases[0].name;
      }
  }
  void _determineWinner(){
    final sizeLobo = widget.selectedPlayers
      .where((player) => (player.state == 'Vivo' || player.state == 'Seleccionado') && player.role == "Lobo")
      .length;
    final sizeNoLobos = widget.selectedPlayers
      .where((player) => (player.state == 'Vivo' || player.state == 'Seleccionado') && player.role != "Lobo")
      .length;
    if (sizeLobo == sizeNoLobos || sizeLobo > sizeNoLobos){
      _whoWonDialog(text: "Ganaron Lobos!!");
      recordActions.add('GANAN LOBOS 🐺');
    }else{
      if (sizeLobo == 0){
        _whoWonDialog(text: "Ganaron Aldeanos!!");
        recordActions.add('GANAN ALDEANOS');
      }
    }
  }
  void showCustomSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20), 
        duration: const Duration(seconds: 3),
      ),
    );
  }
  void _goToNextPhase() {
     setState(() {
      // Obtener las fases actuales (día o noche)
      List<Phase> currentPhases = isDay ? dayPhases : nightPhases;
      // Avanzar al siguiente índice dentro de las fases actuales
      if (currentPhaseIndex < currentPhases.length - 1) {
        currentPhaseIndex++;
      } else {
        // Cambiar entre día y noche y reiniciar el índice
        isDay = !isDay;
        currentPhaseIndex = 0;
        if (!isDay) {
            nightCounter++;
            recordActions.add('NOCHE $nightCounter 🌙');
        } else {
          dayCounter++;
          recordActions.add('DIA $dayCounter ☀️');
        }
      }

      _updateGameState(currentPhases);
      
      if (isDay && dayPhases[currentPhaseIndex].name == 'Asamblea') {
        Player? selectedPlayer; 
        Player? selectedPlayer2;
        //Player? existeSheriff;
        try{
        // Buscar el primer jugador con estado 'Seleccionado'
          selectedPlayer = widget.selectedPlayers.firstWhere((player) => player.state == 'Seleccionado');
          if (selectedPlayer.phoneFlechado != null){
            selectedPlayer2 = widget.selectedPlayers.firstWhere(
            (player) => selectedPlayer?.phone == player.phoneFlechado);
          }
        } catch (e) {
          selectedPlayer = null;
        }

        /*
        existeSheriff = widget.selectedPlayers.firstWhere(
        (player) => (player.secondaryRol == 'Sheriff' && player.state == 'Vivo') || (player.secondaryRol == 'Ayudante' && player.state == 'Vivo'),);
        
        if (existeSheriff.state == 'Vivo' && selectedPlayer?.state == 'Seleccionado' && (selectedPlayer2?.protegidoActivo == null || selectedPlayer?.protegidoActivo == null) && potionPueblo == true){
          _turnSheriff();
        }
        */
        if(selectedPlayer?.protegidoActivo == true || selectedPlayer2?.protegidoActivo == true){
          if(selectedPlayer?.phoneFlechado != null){
            setState(() {
              selectedPlayer?.state = 'Vivo';
              selectedPlayer2?.state = 'Vivo';
              _generateRecord('Se salvaron ${selectedPlayer?.role} - ${selectedPlayer?.name} y ${selectedPlayer2?.role} - ${selectedPlayer2?.name }');
            });
          } else {
            setState(() {
              selectedPlayer?.state = 'Vivo';
              _generateRecord('Se salvó ${selectedPlayer?.role} - ${selectedPlayer?.name}');
            });
          }
        } else{
          // Asignar el estado 'Muerto' si se encontró un jugador
          if (selectedPlayer != null) {
            if(selectedPlayer.phoneFlechado == null) {
              //if (selectedPlayer.rol != 'Lobo')
              setState(() {
                selectedPlayer?.state = 'Muerto';
                lastDeathByWolf = selectedPlayer;
                _generateRecord('Mataron a ${selectedPlayer?.role} - ${selectedPlayer?.name}');
                if (selectedPlayer?.role == 'Cazador'){
                  _turnCazador();
                }
                if (pocionOscura == true && selectedPlayer?.role == 'Alcalde'){
                  _updatePotionAlcalde();
                }
              });
            } else {
              setState(() {
                selectedPlayer?.state = 'Muerto';
                selectedPlayer2?.state = 'Muerto';
                lastDeathByWolf = selectedPlayer;
                _generateRecord('Mataron a ${selectedPlayer?.role} - ${selectedPlayer?.name} que a su vez mataron a ${selectedPlayer2?.role} - ${selectedPlayer2?.name} por estar enamorado');
                if (selectedPlayer?.role == 'Cazador' || selectedPlayer2?.role == 'Cazador'){
                  _turnCazador();
                }
                if (pocionOscura == true && (selectedPlayer?.role == 'Alcalde' || selectedPlayer2?.role == 'Alcalde')){
                  _updatePotionAlcalde();
                }
              });
            }
          } else {
            
          }
        }
      }
      
      _determineWinner();
      
      if (isDay && dayPhases[currentPhaseIndex].name == 'Eleccion Sheriff' && !hasSheriffBeenSelected) {
        _turnSheriff();
        hasSheriffBeenSelected = true;
        //TODO: QUITAR LA SELECCION DEL SHERIFF DE LA LISTA DE FASES
      }
      if (isDay && dayPhases[currentPhaseIndex].name == 'Nominacion') {
        _showTemporizador();
      }

      // Turno para Protector
      if (!isDay && nightPhases[currentPhaseIndex].name == 'Protector') {
        List<Player> protector = List<Player>.from(widget.selectedPlayers.where((player) => player.role == 'Protector'));
        if(protector.isNotEmpty && protector[0].state != 'Muerto'){
          //for (var i = 0; i < 2; i++){
          Player? selectedPlayer;
          //para saber la longitud
          final sizeProtector = widget.selectedPlayers
            .where((player) => player.state == 'Vivo' && player.role == 'Protector')
            .length;
          try{
            // Buscar el primer jugador con estado 'Seleccionado'
            selectedPlayer = widget.selectedPlayers.firstWhere((player) => player.protegidoActivo == true,);
            setState((){
              selectedPlayer?.protegidoActivo = false;
            });
          } catch (e) {
            selectedPlayer = null;
          }
          // print('Longitud de Protector $sizeProtector');
          _turnProtector(sizeProtector, 0);
          //}
        }
      }

      if (!isDay && nightPhases[currentPhaseIndex].name == 'Lobo') {
        _turnLobos();
      }

      if (!isDay && nightPhases[currentPhaseIndex].name == 'Curandero') {
        List<Player> curanderos = List<Player>.from(widget.selectedPlayers.where((player) => player.role == 'Curandero'));
        if(curanderos.isNotEmpty && curanderos[0].state != 'Muerto'){
            // Aquí colocas el código para realizar la acción de curar, si es necesario
          _turnCurandero();
        }
      }
      
      if (!isDay && nightPhases[currentPhaseIndex].name == 'Alcalde') {
        List<Player> curanderos = List<Player>.from(widget.selectedPlayers.where((player) => player.role == 'Alcalde'));
        if(curanderos.isNotEmpty && curanderos[0].state != 'Muerto'){
            // Aquí colocas el código para realizar la acción de curar, si es necesario
          _turnAlcalde();
        }
      }

      if (!isDay && nightPhases[currentPhaseIndex].name == 'Vidente') {
        List<Player> videntes = List<Player>.from(widget.selectedPlayers.where((player) => player.role == 'Vidente'));
        if(videntes.isNotEmpty && videntes[0].state != 'Muerto'){
          if(afectaBrujaVidente == true && (subirImpuesto % 2 == 0)){
            setState((){
              _generateRecord('Vidente no puede usar su habilidad por el alza de impuesto');
            });
          } else {
            _turnVidente();
          }
        }
      }

      if (!isDay && nightPhases[currentPhaseIndex].name == 'Bruja') {
        List<Player> bruja = List<Player>.from(widget.selectedPlayers.where((player) => player.role == 'Bruja'));
        if(bruja.isNotEmpty && bruja[0].state != 'Muerto'){
          if(afectaBrujaVidente == true && (subirImpuesto % 2 == 1)){
            setState((){
              _generateRecord('Bruja no puede usar su habilidad por el alza de impuesto');
            });
          } else {
            _turnBruja();
          }
        }
      }
    });
  }

  void _editItem(int index, Player player) {
    // final secondaryRolController = DropdownButtonFormField(items: items, onChanged: onChanged);
    // final stateController = TextEditingController(text: player.state);
    final secondaryRolController = TextEditingController(text: player.secondaryRol);    
    final numberSeatController = TextEditingController(text: player.numberSeat);
    final roleController = TextEditingController(text: player.role);
    final phoneController = TextEditingController(text: player.phone);

    String selectedSecondaryRole = player.secondaryRol ?? '';
    String selectedStatePlayer = player.state ?? '';
    // final List<String?> secondaryRoles = ['Sheriff', 'Ayudante', null];
    final List<String> states = ['Vivo', 'Muerto', 'Seleccionado'];


    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Editar campos'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: roleController,decoration: const InputDecoration(labelText: 'Rol Principal'),),
                    //  DropdownButtonFormField<String>(
                    //     value: selectedSecondaryRole.isNotEmpty ? selectedSecondaryRole : null,
                    //     decoration: const InputDecoration(labelText: 'Rol Secundario'),
                    //     items: secondaryRoles.map((role) {
                    //       return DropdownMenuItem(value: role, child: Text(role?? 'Sin rol secundario'));
                    //     }).toList(),
                    //     onChanged: (value) {
                    //       if (value != null) {
                    //         setModalState(() {
                    //           selectedSecondaryRole = value;
                    //         });
                    //       }
                    //     },
                    //   ),
                    TextField(controller: secondaryRolController,decoration: const InputDecoration(labelText: 'Rol Secundario'),),
                    // TextField(controller: stateController,decoration: const InputDecoration(labelText: 'Estado'),),
                    DropdownButtonFormField(
                      value: selectedStatePlayer.isNotEmpty ? selectedStatePlayer : null,
                      items: states.map((state){
                        return DropdownMenuItem(value: state, child: Text(state));
                      }).toList(), 
                      onChanged: (value){
                        setModalState(() {
                          selectedStatePlayer = value!;
                        });
                    }),
                    TextField(controller: numberSeatController,decoration: const InputDecoration(labelText: 'No. Asiento'),),
                    TextField(controller: phoneController,decoration: const InputDecoration(labelText: 'Teléfono'),),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      player.secondaryRol = selectedSecondaryRole;
                      player.state = selectedStatePlayer;
                      player.numberSeat = numberSeatController.text;
                      player.role = roleController.text;
                      player.secondaryRol = secondaryRolController.text;
                      player.phone = phoneController.text;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  Player? _getPlayerByState(String state){
    try{
      return widget.selectedPlayers.firstWhere((player) => player.state == state);
    } catch(e){
      return null;
    }
  }
  //Modal lobos
  void _turnSheriff() {
    Player? selectedPlayer = _getPlayerByState('Seleccionado'); // Jugador seleccionado actualmente
    Player? selectedPlayer2;
    
    if (selectedPlayer != null && selectedPlayer.phoneFlechado != null){
      try{
        selectedPlayer2 = widget.selectedPlayers.firstWhere((player) => selectedPlayer.phone == player.phoneFlechado);
      } catch (e) {
        selectedPlayer2 = null;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Text('Quieres usar la poción del pueblo para salvar a ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName}'),
          actions: [
            TextButton(
              onPressed: () {
                if(selectedPlayer?.phoneFlechado == null) {
                  //if (selectedPlayer.rol != 'Lobo')
                  setState(() {
                    _generateRecord('No se uso la poción para salvar a ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName}');
                    selectedPlayer?.state = 'Muerto';
                    Navigator.of(context).pop();
                  });
                } else {
                  setState(() {
                    selectedPlayer?.state = 'Muerto';
                    selectedPlayer2?.state = 'Muerto';
                    _generateRecord('No se uso la poción para salvar a ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName} y también mataron a ${selectedPlayer2?.role} - ${selectedPlayer2?.name} ${selectedPlayer2?.lastName} porque estaba flechado');
                    Navigator.of(context).pop();
                  });
                }
                setState((){
                  _generateRecord('No se uso la poción para salvar a ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName}');
                  selectedPlayer?.state = 'Muerto';
                  Navigator.of(context).pop();
                });
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState((){
                  _generateRecord('Se uso la poción para salvar a ${selectedPlayer?.role} - ${selectedPlayer?.name} ${selectedPlayer?.lastName}');
                  selectedPlayer?.state = 'Vivo';
                  potionPueblo = false;
                  Navigator.of(context).pop();
                });
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  //temporizador
  void _showTemporizador() {
    const int totalSeconds = 5 * 60; // 5 minutos en segundos
    // const int totalSeconds = 5 * 1; // 5 minutos en segundos
    int remainingSeconds = totalSeconds;
    Timer? timer;
    Player? selectedPlayer; // Jugador seleccionado actualmente
    Player? selectedPlayer2; // Jugador seleccionado actualmente

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row (
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cuenta Regresiva"),
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue),
                onPressed: () {
                  _showPlayers();// Cierra el diálogo
                },
              ),
            ]
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Iniciar el temporizador
              timer ??= Timer.periodic(const Duration(seconds: 1), (Timer t) {
                if (remainingSeconds > 0) {
                  setState(() { remainingSeconds--;});
                } else {
                  t.cancel();
                }
              });
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Tiempo restante: ${_formatTime(remainingSeconds)}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: widget.selectedPlayers
                    .where((player) => player.state?.toLowerCase() != 'muerto' && player.protegidoActivo != true) // Excluir jugadores Muertos
                    .map((player) {
                    return DropdownMenuItem<Player>(value: player, child: Text("${player.numberSeat} - ${player.name} ${player.lastName}"));}).toList(),
                  onChanged: (Player? newValue) {
                    setState(() {
                      selectedPlayer = newValue;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed:() {
                  _randomPlayerToKill();
                  Navigator.of(context).pop();
                  }, 
                  child: Text("Matar al azar"))
              ],
            );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (timer != null) timer?.cancel(); // Cancelar el temporizador
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                /*revisoSheriff = widget.selectedPlayers.firstWhere(
                  (player) => (player.secondaryRol == 'Sheriff' && player.state == 'Vivo') || (player.secondaryRol == 'Ayudante' && player.state == 'Vivo'),);
                */
                try {
                  selectedPlayer2 = widget.selectedPlayers.firstWhere((player) => selectedPlayer?.phone == player.phoneFlechado);
                } catch (e){
                  selectedPlayer2 = null;
                }
                if (selectedPlayer?.phoneFlechado != null && selectedPlayer2 != null){
                  if(selectedPlayer2 == null){ //Si no eligen a nadie en la asamblea
                    setState((){
                      _generateRecord('En la asamblea no se eligió a nadie');
                      Navigator.of(context).pop();
                    });
                  }
                  
                  if ((selectedPlayer2?.protegidoActivo == true)){
                    setState((){
                      _generateRecord('En la asamblea se eligió para matar a ${selectedPlayer?.role} - ${selectedPlayer?.name} pero esta protegido');
                      Navigator.of(context).pop();
                    });
                  } else {
                    setState((){
                      _generateRecord('En la asamblea se eligió para matar a ${selectedPlayer?.role} - ${selectedPlayer?.name} que a su vez mataron a ${selectedPlayer2?.role} - ${selectedPlayer2?.name} por estar enamorado');
                      selectedPlayer?.state = 'Muerto';
                      selectedPlayer2?.state = 'Muerto';
                      lastDeathByWolf = selectedPlayer;
                      Navigator.of(context).pop();
                      if (selectedPlayer?.role == 'Cazador' || selectedPlayer2?.role == 'Cazador'){
                        _turnCazador();
                      }
                      if (pocion == true && (selectedPlayer?.role == 'Alcalde' || selectedPlayer2?.role == 'Alcalde')){
                        _updatePotionAlcalde();
                      }
                    });
                  }
                } else {
                  if (selectedPlayer == null){
                    setState((){
                      _generateRecord('No se escogió a nadie para matar');
                      Navigator.of(context).pop();
                    });
                  }else {
                    setState((){
                      _generateRecord('En la asamblea se eligió para matar a ${selectedPlayer?.role} - ${selectedPlayer?.name}');
                      selectedPlayer?.state = 'Muerto';
                      lastDeathByWolf = selectedPlayer;
                      Navigator.of(context).pop();
                      if (selectedPlayer?.role == 'Cazador'){
                        _turnCazador();
                      }
                      if (pocion == true && selectedPlayer?.role == 'Alcalde'){
                        _updatePotionAlcalde();
                      }
                    });
                  }
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    ).then((_) {
      if (timer != null) timer?.cancel(); // Asegurarse de cancelar el temporizador
    });
  }

  void _randomPlayerToKill(){
    //Filtrar jugadores vivos
    List<Player> playersAlive = _getPlayersStillAlive();
    Player? selectedPlayer2; 
    if(playersAlive.isNotEmpty){
      Random random = Random();
      int indexAleatorio = random.nextInt(playersAlive.length);

      //Obtener player al azar
      Player playerSelectedToKill = playersAlive[indexAleatorio];
      
      if (playerSelectedToKill.phoneFlechado != null && playerSelectedToKill.protegidoActivo != true) {
        selectedPlayer2 = playersAlive.firstWhere(
        (player) => playerSelectedToKill.phone == player.phoneFlechado);
        if (selectedPlayer2.protegidoActivo == true){
          setState(() {
            _generateRecord('El destino eligió para matar a: ${playerSelectedToKill.role} - ${playerSelectedToKill.name} pero esta protegido por ${selectedPlayer2?.role} - ${selectedPlayer2?.name}');
          });
        } else {
          setState(() {
            playerSelectedToKill.state = "Muerto"; // Cambiar el estado a "muerto"
            selectedPlayer2?.state = "Muerto"; // Cambiar el estado a "muerto"
            _generateRecord('El destino eligió para matar a: ${playerSelectedToKill.role} - ${playerSelectedToKill.name} y ${selectedPlayer2?.role} - ${selectedPlayer2?.name} el cual estaba flechado');
            if (playerSelectedToKill.role == 'Cazador' || selectedPlayer2?.role == 'Cazador'){
              _turnCazador();
            }
          });
        }
      } else{
        if (playerSelectedToKill.protegidoActivo == true) {
          setState((){
            _generateRecord('El destino eligió para matar a: ${playerSelectedToKill.role} - ${playerSelectedToKill.name}, pero esta protegido, NO SE PUDO MATAR');
          });
        } else {
          setState(() {
            playerSelectedToKill.state = "Muerto"; // Cambiar el estado a "muerto"
            _generateRecord('El destino eligió para matar a: ${playerSelectedToKill.role} - ${playerSelectedToKill.name}');
            if (playerSelectedToKill.role == 'Cazador'){
              _turnCazador();
            }
          });
        }
      }
    }
    else{
      showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mensaje Importante'),
          content: Text('Ya no hay mas jugadores para matar'),
          actions: <Widget>[
            TextButton(onPressed: () {Navigator.of(context).pop();},child: Text('Cerrar'),),
          ],
        );
      },
      );
    }
  }

  void _generateRecord(String message){
    recordActions.add(message);
  }

  List<Player> _getPlayersStillAlive() {
    return List<Player>.from(widget.selectedPlayers.where((jugador) => jugador.state == 'Vivo'));
  }
  //Modal lobos
  void _turnLobos() {
    Player? selectedPlayer; // Jugador seleccionado actualmente

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row (
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Lobos"),
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue),
                onPressed: () {
                  _showPlayers();// Cierra el diálogo
                },
              ),  
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // 1. Filtrar y ordenar jugadores antes del Dropdown
            List<Player> filteredAndSortedPlayers = widget.selectedPlayers
                .where((player) =>
                    player.state?.toLowerCase() != 'muerto' &&
                    player.protegidoActivo != true)
                .toList();
            filteredAndSortedPlayers.sort(
                (player1, player2) => player1.numberSeat!.compareTo(player2.numberSeat!));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: filteredAndSortedPlayers
                    .map<DropdownMenuItem<Player>>((player) {
                    return DropdownMenuItem<Player>(
                      value: player,
                      child: Text("${player.numberSeat} - ${player.name} ${player.lastName}"),
                    );
                  }).toList(),
                  onChanged: (Player? newValue) {
                    setState(() {
                      selectedPlayer = newValue;
                    });
                  },
                ),
              ],
            );
            },
          ),
          actions: [
            TextButton(onPressed: () {Navigator.of(context).pop();}, child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                setState((){
                  _generateRecord('Lobos seleccionaron a ${selectedPlayer?.role} - ${selectedPlayer?.name }');
                  selectedPlayer?.state = 'Seleccionado';
                  Navigator.of(context).pop();
                });
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }
    //Modal Curandero
  void _turnCurandero() {
    Player? selectedPlayer; // Jugador seleccionado actualmente

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Curandero"),
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue),
                onPressed: () {
                  _showPlayers();// Cierra el diálogo
                },
              ),
            ]
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              List<Player> filteredAndSortedPlayers = widget.selectedPlayers
                .where((player) => player.curado != 2 && player.state != 'Muerto').toList();
                filteredAndSortedPlayers.sort((player1, player2) => player1.numberSeat!.compareTo(player2.numberSeat!));
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropdown para seleccionar jugador
                    DropdownButton<Player>(
                      hint: const Text("Seleccione un jugador"),
                      value: selectedPlayer,
                      items: filteredAndSortedPlayers
                        .map<DropdownMenuItem<Player>>((player) {
                        return DropdownMenuItem<Player>(
                          value: player,
                          child: Text("${player.numberSeat} - ${player.name} ${player.lastName}"),
                        );
                      }).toList(),
                      onChanged: (Player? newValue) {
                        setState(() {
                          selectedPlayer = newValue;
                        });
                      },
                    ),
                  ],
                );
            },
          ),
          actions: [
            TextButton(onPressed: () {Navigator.of(context).pop();},child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                if (selectedPlayer?.curado == null){
                  setState(() {
                    selectedPlayer?.state = 'Vivo';
                    selectedPlayer?.curado += 1;
                    Navigator.of(context).pop();
                  });
                } else{
                  if (selectedPlayer!.curado < 2){
                    setState(() {
                      selectedPlayer?.state = 'Vivo';
                      curanderoTimesBeenSaved++;
                      selectedPlayer!.curado += 1;
                      Navigator.of(context).pop();
                    });
                  }
                  else {
                    setState((){
                      Navigator.of(context).pop();
                    });
                  }
                }
                _generateRecord("Curanderos seleccionaron a ${selectedPlayer?.role} - ${selectedPlayer?.name}");
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void _showPlayers(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Jugadores'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.selectedPlayers.map((player) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                  color: player.state?.toLowerCase() == "vivo" ? const Color.fromARGB(147, 49, 220, 98) : player.state?.toLowerCase() == "muerto" ? Colors.red.shade300 : const Color.fromARGB(136, 229, 255, 0),
                  borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text('${player.numberSeat} - ${player.role} - ${player.name} ${player.lastName} - ${player.state} - Rol Secundario: ${player.secondaryRol} '),
                    // subtitle: Text('- Rol Secundario: ${player.secondaryRol}'),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () {Navigator.of(context).pop();}, child: const Text('Cerrar')),
          ],
        );
      },
    );
  }

  //Modal Protector
  void _turnProtector(int numSize, int indice) {
    Player? selectedPlayer; // Jugador seleccionado actualmente
    List<Player> protectores = List<Player>.from(widget.selectedPlayers.where((player) => player.role == 'Protector')).toList();
    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Protector ${protectores[indice].name}"),
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue),
                onPressed: () {
                  _showPlayers();// Cierra el diálogo
                },
              ),
            ]
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              List<Player> filteredAndSortedPlayers = widget.selectedPlayers
                .where((player) => player.protegido != 2 && player.state?.toLowerCase() != 'muerto').toList(); // Excluir jugadores Muertos
                filteredAndSortedPlayers.sort(
                (player1, player2) => player1.numberSeat!.compareTo(player2.numberSeat!));
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown para seleccionar jugador
                  DropdownButton<Player>(
                    hint: const Text("Seleccione un jugador"),
                    value: selectedPlayer,
                    items: filteredAndSortedPlayers
                      .map<DropdownMenuItem<Player>>((player) {
                      return DropdownMenuItem<Player>(
                        value: player,
                        child: Text("${player.numberSeat} - ${player.name} ${player.lastName}"),
                      );
                    }).toList(),
                    onChanged: (Player? newValue) {
                      setState(() {
                        selectedPlayer = newValue;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () {Navigator.of(context).pop(); },child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                if (selectedPlayer?.protegido == null){
                  setState(() {
                    selectedPlayer?.protegidoActivo = true;
                    selectedPlayer?.protegido += 1;
                    Navigator.of(context).pop();
                  });
                } else{
                  if (selectedPlayer!.protegido < 2){
                    setState(() {
                      selectedPlayer?.protegidoActivo = true;
                      curanderoTimesBeenSaved++;
                      selectedPlayer!.protegido += 1;
                      Navigator.of(context).pop();
                    });
                  }
                  else {
                    setState((){
                      Navigator.of(context).pop();
                    });
                  }
                }
                _generateRecord("Protector ${protectores[indice].name} seleccionó a ${selectedPlayer?.role} - ${selectedPlayer?.name}");
                if(numSize > 1){
                  _turnProtector(numSize - 1, indice+1);
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  //Modal Cupido
  void _turnCupido() {

    Player? selectedPlayer1; // Jugador seleccionado actualmente
    Player? selectedPlayer2; // Jugador seleccionado actualmente

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cupido"),
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue),
                onPressed: () {
                  _showPlayers();// Cierra el diálogo
                },
              ),
            ]
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              List<Player> filteredAndSortedPlayers = widget.selectedPlayers
                .where((player) => player.protegido != 2).toList();

                filteredAndSortedPlayers.sort((player1, player2) => player1.numberSeat!.compareTo(player2.numberSeat!));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown para seleccionar jugador
                  DropdownButton<Player>(
                    hint: const Text("Seleccione primer jugador"),
                    value: selectedPlayer1,
                    items: filteredAndSortedPlayers
                      .map((player) {
                      return DropdownMenuItem<Player>(
                        value: player,
                        child: Text("${player.numberSeat} - ${player.name} ${player.lastName}"),
                      );
                    }).toList(),
                    onChanged: (Player? newValue) {
                      setState(() {
                        selectedPlayer1 = newValue;
                      });
                    },
                  ),
                  DropdownButton<Player>(
                    hint: const Text("Seleccione segundo jugador"),
                    value: selectedPlayer2,
                    items: filteredAndSortedPlayers
                      .map((player) {
                      return DropdownMenuItem<Player>(
                        value: player,
                        child: Text("${player.numberSeat} - ${player.name} ${player.lastName}"),
                      );
                    }).toList(),
                    onChanged: (Player? newValue) {
                      setState(() {
                        selectedPlayer2 = newValue;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () {Navigator.of(context).pop();},child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                if(selectedPlayer1 != null && selectedPlayer2 != null){
                  //Verificar que no sean el mismo jugador
                  if (selectedPlayer1 == selectedPlayer2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No puedes seleccionar al mismo jugador dos veces."))
                    );
                    return;
                  }
                  String phonePlayer1 = selectedPlayer1!.phone.trim();
                  String phonePlayer2 = selectedPlayer2!.phone.trim();
                  if(phonePlayer1.isEmpty && phonePlayer2.isEmpty){
                    selectedPlayer1?.phone = '1234';
                    selectedPlayer2?.phone = '12345';
                  }
                  else if(phonePlayer1.isEmpty ){
                    selectedPlayer1?.phone = '1234';
                  }
                  else if(phonePlayer2.isEmpty ){
                    selectedPlayer2?.phone = '12345';
                  } 
                  setState(() {
                    selectedPlayer1?.phoneFlechado = selectedPlayer2?.phone;
                    selectedPlayer2?.phoneFlechado = selectedPlayer1?.phone;
                    hasCupidoBeenSelected = true;
                  });
                  Navigator.of(context).pop();
                  _generateRecord("Cupido selecciono a ${selectedPlayer1?.role} - ${selectedPlayer1?.name} y ${selectedPlayer2?.role} - ${selectedPlayer2?.name}");
                
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  //Modal Vidente
  void _turnVidente() {
    Player? selectedPlayer; // Jugador seleccionado actualmente

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Vidente"),
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue),
                onPressed: () {
                  _showPlayers();// Cierra el diálogo
                },
              ),
            ]
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              List<Player> filteredAndSortedPlayers = widget.selectedPlayers
                .where((player) => player.state?.toLowerCase() != 'muerto').toList(); // Excluir jugadores Muertos

              filteredAndSortedPlayers.sort(
              (player1, player2) => player1.numberSeat!.compareTo(player2.numberSeat!));
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: filteredAndSortedPlayers
                    .map<DropdownMenuItem<Player>>((player) {
                    return DropdownMenuItem<Player>(
                      value: player,
                      child: Text("${player.numberSeat} - ${player.name} ${player.lastName}"),
                    );
                  }).toList(),
                  onChanged: (Player? newValue) {
                    setState(() {
                      selectedPlayer = newValue;
                    });
                  },
                ),
                Text("${selectedPlayer == null ? '' : 'El jugador que elegiste es: ${selectedPlayer?.role}'} ")
              ],
            );
            },
          ),
          actions: [
            TextButton(onPressed: () {Navigator.of(context).pop();},child: const Text("Cancelar"),),
            TextButton(
              onPressed: () {
                setState((){
                  _generateRecord("Vidente quiso saber el rol de ${selectedPlayer?.role} - ${selectedPlayer?.name}");
                  Navigator.of(context).pop();
                });
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  //Modal Bruja
  void _turnBruja() {
    Player? selectedPlayer; // Jugador seleccionado actualmente
    Player? selectedPlayer2; // Jugador que esta relacionado con el anterior

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bruja"),
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue),
                onPressed: () {
                  _showPlayers();// Cierra el diálogo
                },
              ),
            ]
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              List<Player> filteredAndSortedPlayers = widget.selectedPlayers
                .where((player) => player.state?.toLowerCase() != 'muerto').toList(); // Excluir jugadores Muertos

                filteredAndSortedPlayers.sort(
                (player1, player2) => player1.numberSeat!.compareTo(player2.numberSeat!));
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown para seleccionar jugador
                  DropdownButton<Player>(
                    hint: const Text("Seleccione un jugador"),
                    value: selectedPlayer,
                    items: filteredAndSortedPlayers
                      .map<DropdownMenuItem<Player>>((player) {
                      return DropdownMenuItem<Player>(
                        value: player,
                        child: Text("${player.numberSeat} - ${player.name} ${player.lastName}"),
                      );
                    }).toList(),
                    onChanged: (Player? newValue) {
                      setState(() {
                        selectedPlayer = newValue;
                      });
                    },
                  ),
                  Text(selectedPlayer != null ? 
                        (selectedPlayer?.role == 'Lobo' ? 
                            'El jugador que elegiste es: ${selectedPlayer?.role}' 
                            :'No puedes saber el rol de este jugador')
                        : 'Aun no seleccionas ningun jugador')
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () {Navigator.of(context).pop();},child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                if (selectedPlayer?.phoneFlechado != null){
                  selectedPlayer2 = widget.selectedPlayers.firstWhere(
                  (player) => selectedPlayer?.phone == player.phoneFlechado);
                }
                //optimizar este bloque
                //revisamos si esta protegido por lo cual si esta protegido y es lobo no puede matarlo
                if((selectedPlayer?.protegidoActivo == true || selectedPlayer2?.protegidoActivo == true) && selectedPlayer?.role == 'Lobo'){
                  setState((){
                    _generateRecord('Bruja descubrió pero no lo pudo matar porque esta protegido: ${selectedPlayer?.role} - ${selectedPlayer?.name}');
                    Navigator.of(context).pop();
                  });
                } else{
                  if (selectedPlayer?.phoneFlechado != null && selectedPlayer?.role == 'Lobo'){
                    setState(() {
                      selectedPlayer?.state = 'Muerto';
                      selectedPlayer2?.state = 'Muerto';
                      _generateRecord('Bruja descubrió a ${selectedPlayer?.role} - ${selectedPlayer?.name} y además mató a ${selectedPlayer2?.role} - ${selectedPlayer2?.name} porque estaba enamorado');
                      Navigator.of(context).pop();
                    });
                  } else {
                    if (selectedPlayer?.role == 'Lobo'){
                      setState(() {
                        selectedPlayer?.state = 'Muerto';
                        _generateRecord('Bruja descubrió y mató a ${selectedPlayer?.role} - ${selectedPlayer?.name}');
                        Navigator.of(context).pop();
                      });
                    }
                    else {
                      setState((){
                        _generateRecord('Bruja no pudo matar a ${selectedPlayer?.role} - ${selectedPlayer?.name} porque no es lobo');
                        Navigator.of(context).pop();
                      });
                    }
                  }
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

    //Modal informativo
  Future<bool> _turnInfo(levelPhases) async{
    return await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Información importante"),
        content: Text('Escoger Sheriff y Ayudante'
          '${levelPhases.level != 'Principiante' ? ', además hay Cupido' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Salir
            child: Text("Aceptar"),
          ),
        ],
      )
    );    
  }

  //Modal Cazador
  void _turnCazador() {
    Player? selectedPlayer; // Jugador seleccionado actualmente
    Player? selectedPlayer2; // Jugador que esta relacionado con el anterior

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cazador"),
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue),
                onPressed: () {
                  _showPlayers();// Cierra el diálogo
                },
              ),
            ]
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              List<Player> filteredAndSortedPlayers = widget.selectedPlayers
                .where((player) => player.state?.toLowerCase() != 'muerto').toList(); // Excluir jugadores Muertos

                filteredAndSortedPlayers.sort(
                (player1, player2) => player1.numberSeat!.compareTo(player2.numberSeat!));
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown para seleccionar jugador
                  DropdownButton<Player>(
                    hint: const Text("Seleccione un jugador"),
                    value: selectedPlayer,
                    items: filteredAndSortedPlayers
                      .map<DropdownMenuItem<Player>>((player) {
                      return DropdownMenuItem<Player>(
                        value: player,
                        child: Text("${player.numberSeat} - ${player.name} ${player.lastName}"),
                      );
                    }).toList(),
                    onChanged: (Player? newValue) {
                      setState(() {
                        selectedPlayer = newValue;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () {
              setState((){
                _generateRecord('Cazador prefirio no llevarse a nadie');
                Navigator.of(context).pop();
              });},
              child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                if (selectedPlayer?.phoneFlechado != null){
                  selectedPlayer2 = widget.selectedPlayers.firstWhere(
                  (player) => selectedPlayer?.phone == player.phoneFlechado);
                }
                //optimizar este bloque
                //revisamos si esta protegido por lo cual si esta protegido y es lobo no puede matarlo
                if((selectedPlayer?.protegidoActivo == true || selectedPlayer2?.protegidoActivo == true)){
                  setState((){
                    _generateRecord('Cazador no pudo llevarse a ${selectedPlayer?.role} - ${selectedPlayer?.name} porque esta protegido');
                    Navigator.of(context).pop();
                  });
                } else{
                  if (selectedPlayer?.phoneFlechado != null){
                    setState(() {
                      selectedPlayer?.state = 'Muerto';
                      selectedPlayer2?.state = 'Muerto';
                      _generateRecord('Cazador se llevo a ${selectedPlayer?.role} - ${selectedPlayer?.name} y además mató a ${selectedPlayer2?.role} - ${selectedPlayer2?.name} porque estaba enamorado');
                      Navigator.of(context).pop();
                    });
                  } else {
                    setState((){
                      selectedPlayer?.state = 'Muerto';
                      _generateRecord('Cazador se llevo a ${selectedPlayer?.role} - ${selectedPlayer?.name}');
                      Navigator.of(context).pop();
                    });
                  }
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  //Modal Alcalde
  void _turnAlcalde() {
    Player? selectedPlayer;  // Jugador que esta relacionado con el anterior

    try{
      selectedPlayer = widget.selectedPlayers.firstWhere(
        (player) => (player.role == 'Alcalde'));
    } catch (e){
      selectedPlayer = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Alcalde"),
            ]
          ),
          content: Text('Subir o bajar impuestos?'),
          actions: [
            TextButton(
              onPressed: () {
                setState((){
                  _generateRecord('${selectedPlayer?.role} - ${selectedPlayer?.name} bajó los impuestos');
                  bajarImpuesto = bajarImpuesto + 1;
                  afectaBrujaVidente = false;
                  if (bajarImpuesto == 1 && pocionOscura == false){
                    pocion = true;
                    _generateRecord('Alcalde obtuvo poción');
                  }
                  Navigator.of(context).pop();
                });
              },
              child: const Text("Bajar impuestos")),
            TextButton(
              onPressed: () {
                setState((){
                  _generateRecord('${selectedPlayer?.role} - ${selectedPlayer?.name} subió los impuestos');
                  afectaBrujaVidente = true;
                  subirImpuesto = subirImpuesto + 1;
                  if (subirImpuesto == 1 && pocion == false){
                    pocionOscura = true;
                    _generateRecord('Alcalde obtuvo poción oscura');
                  }
                  Navigator.of(context).pop();
                });
              },
              child: const Text("Subir Impuestos"),
            ),
          ],
        );
      },
    );
  }

  void _whoWonDialog({String? text}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: const Text("Ganador"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('$text')],
            );
            },
          ),
          actions: [
            TextButton( onPressed: () { Navigator.of(context).pop();},child: const Text("Cancelar")),
            TextButton( onPressed: () {Navigator.of(context).pop();},child: const Text("Aceptar")),
          ],
        );
      },
    );
  }

  String _formatTime(int totalSeconds) {
    final int minutes = ((totalSeconds / 60) % 60).floor();
    final int seconds = (totalSeconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool shouldShowDeathIcon(){
    // Verifica si estamos en una fase válida
    if ((isDay && (dayPhases.isEmpty || currentPhaseIndex >= dayPhases.length)) ||
        (!isDay && (nightPhases.isEmpty || currentPhaseIndex >= nightPhases.length))) {
      return false; // No hay fase válida
    }
      String currentPhaseName = isDay ? dayPhases[currentPhaseIndex].name : nightPhases[currentPhaseIndex].name;

      if(currentPhaseName == 'Bruja'){
        return !widget.selectedPlayers.any((player) => player.role == 'Bruja' && (player.state == 'Vivo' || player.state == 'Seleccionado'));
      } if(currentPhaseName == 'Lobo'){
        return !widget.selectedPlayers.any((player) => player.role == 'Lobo' && (player.state == 'Vivo' || player.state == 'Seleccionado'));
      } if(currentPhaseName == 'Vidente'){
        return !widget.selectedPlayers.any((player) => player.role == 'Vidente' && (player.state == 'Vivo' || player.state == 'Seleccionado'));
      } if(currentPhaseName == 'Curandero'){
        return !widget.selectedPlayers.any((player) => player.role == 'Curandero' && (player.state == 'Vivo' || player.state == 'Seleccionado'));
      } if(currentPhaseName == 'Protector'){
        return !widget.selectedPlayers.any((player) => player.role == 'Protector' && (player.state == 'Vivo' || player.state == 'Seleccionado'));
      } 
      return false;
  }
  bool existsRolSecondary(String rolSecondary){
    return widget.selectedPlayers.any(
      (player) => player.secondaryRol == rolSecondary && player.state == 'Vivo',
    );
  }

  Future <void> openWhatsApp({
    required String phone,
    String? text,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final String textAndroid = text != null ? Uri.encodeFull('&text=$text') : '';
    final String urlAndroid = 'https://wa.me/send?phone=$phone?text=$textAndroid';
    final String effectiveURL = urlAndroid;
    if(await canLaunchUrl(Uri.parse(effectiveURL))) {
      await launchUrl(Uri.parse(effectiveURL), mode: mode);
    } else {
      throw Exception('openWhatsApp could not launching url: $effectiveURL');
    }
  }

  Future<void> sendWhatsAppMessagesToAll(List<Player> players) async {
    for (var player in players) {
      final String phone = player.phone;
      final String message = Uri.encodeFull('Noche del lobo! tu rol es el siguiente: ${player.role}');
      final String url = 'https://wa.me/$phone?text=$message';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // print('Error al abrir WhatsApp con el número: $phone');
      }
      await Future.delayed(Duration(seconds: 2)); // Pequeña pausa entre envíos
    }
}
  Future<void> sendSMSMessagesToAll(List<Player> players) async {
    for (var player in players) {
      final String phone = player.phone;
      final String message = Uri.encodeFull('Noche del lobo! Tu rol es: ${player.role}');
      final String smsUrl = 'sms:$phone?body=$message';

      if (await canLaunch(smsUrl)) {
        await launch(smsUrl);
      } else {
        // print('No se pudo enviar SMS a: $phone');
      }
      await Future.delayed(Duration(seconds: 2)); // Pausa entre mensajes
    }
  }

  Future<bool> _confirmExit() async{
      return await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Deseas salir de la partida?"),
        content: const Text('¿Estás seguro que deseas salir? Se perderá la partida y los roles.'),
        actions: [
          TextButton(
                onPressed: () => Navigator.of(context).pop(false), // No salir
                child: Text("Cancelar"),
              ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Salir
            child: Text("Salir"),
          ),
        ],
      )
    );    
  }
 @override
  Widget build(BuildContext context) {
    double fontSize = 17;
    int numberWolfAlive = widget.selectedPlayers.where((player) => player.role == 'Lobo' && (player.state == 'Vivo' || player.state == 'Seleccionado')).length;
    int numberFarmerAlive = widget.selectedPlayers.where((player) => player.role != 'Lobo' && (player.state == 'Vivo' || player.state == 'Seleccionado')).length;
    //List<PhasesByLevel> phases = loadPhases();
    //final levelPhases = phases.firstWhere((phase) => phase.level == widget.level);
    return PopScope(
      canPop: false, //Evita salir por defecto
      onPopInvokedWithResult: (didPop, result) async{
        if(didPop) return;
        final shouldExit = await _confirmExit();
        if (!context.mounted) return; // Seguridad: widget fue desmontado
        if(shouldExit){
          Navigator.of(context).pop(result);
        }
      }, // Llamamos a la función
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('JUEGO LOBO - ${widget.level} - Jugadores: ${widget.selectedPlayers.length} - 🐺: $numberWolfAlive - 🧑‍🌾: $numberFarmerAlive'),
        ),
        body: Container(
          margin: const EdgeInsets.all(15.5), //16 px en todos los lados
          child: Column(
            children: [
              //Cuadros de informacion y botón
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text('Estado: ${isDay? '☀️' : '🌙'}', style: TextStyle(fontSize: fontSize),),
                    ),
                  ),
                  /*// Turno para Cupido
                  if (isDay && levelPhases.level != 'Principiante' && !hasCupidoBeenSelected) {
                    _turnCupido();
                    hasCupidoBeenSelected = true;
                  }*/
                  if(widget.level != 'Principiante')
                    FilledButton.icon(
                      onPressed: _turnCupido,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isDay && !hasCupidoBeenSelected) ? const Color.fromARGB(255, 255, 71, 132) : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                        padding: const EdgeInsets.all(10),
                      ),
                      icon: Icon(Icons.favorite),
                      label: Text('Cupido', style: TextStyle(fontSize: fontSize)),
                    ),
                  FilledButton.icon(
                    onPressed: _updatePotions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (potions >= 1 && potionSheriff == true && existsRolSecondary('Sheriff')) ? Colors.amber : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: Icon(Icons.science_outlined),
                    label: Text('Sheriff', style: TextStyle(fontSize: fontSize)),
                  ),
                  FilledButton.icon(
                    onPressed: _updatePotions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (potions >= 2 && potionPueblo == true && (existsRolSecondary('Sheriff') || existsRolSecondary('Ayudante'))) ? Colors.blue : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: Icon(Icons.science_outlined),
                    label: Text('Pueblo', style: TextStyle(fontSize: fontSize)),
                    
                  ),
                  FilledButton.icon(
                    onPressed: _updatePotions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (potions > 2 && potionAyudante == true && existsRolSecondary('Ayudante')) ? Colors.deepOrangeAccent : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: Icon(Icons.science_outlined),
                    label: Text('Ayudante', style: TextStyle(fontSize: fontSize)),
                    
                  ),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    color: Colors.blue[700],
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text("Estado Actual: $gameState ${shouldShowDeathIcon() ? '☠️' : ''}", style: TextStyle(fontSize: fontSize)),
                    ) ,
                  ),
                  //Boton siguiente fase
                  FilledButton.icon(
                    onPressed: _goToNextPhase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: Icon(Icons.arrow_forward_rounded),
                    label: Text('Fase: $nextStatePhase ' , style: TextStyle(fontSize: fontSize)),
                  ),
                ],
              ),
              _buildPlayerListView(),
              
          // Aquí usamos un ListView para mostrar las acciones
              SizedBox(
                height: 130,
                child: ListView.builder(
                  itemCount: recordActions.length,
                  itemBuilder: (context, index) {
                    // return ListTile(
                    //   title: Text(recordActions[index]), // Mostrar cada acción en la lista
                    // );
                    if(recordActions[index].contains('NOCHE') || recordActions[index].contains('DIA')){
                      return Text(recordActions[index], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0,)); // Mostrar cada acción en la lista
                    }
                    return  Text(recordActions[index], style: TextStyle( fontSize: 17.0,)); // Mostrar cada acción en la lista
                    
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  //Mostrar los datos
  Widget _buildPlayerListView() {
    return Expanded(
      child: ListView.builder(
        itemCount: widget.selectedPlayers.length,
        itemBuilder: (context, index) {
          final player = widget.selectedPlayers[index];
          // Condición para resaltar el renglón en rojo para hacer los cambios dinamicamente
          //final isAlive = player.state?.toLowerCase() == "vivo";
          return Card(
            color: player.state?.toLowerCase() == "vivo" ? const Color.fromARGB(147, 49, 220, 98) : player.state?.toLowerCase() == "muerto" ? Colors.red.shade300 : const Color.fromARGB(136, 229, 255, 0),
            margin: EdgeInsets.all(4),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //mostrar los datos en columnas
                children: [
                  Expanded(child: Text(player.numberSeat ?? '', style: TextStyle( fontSize: 20.0,))),
                  Expanded(child: Text('${player.name} ${player.lastName}',style: TextStyle(fontSize: 20.0,))),
                  Expanded(child: Text(player.role,style: TextStyle(fontSize: 20.0,))),
                  Expanded(child: Text(player.secondaryRol ?? '',style: TextStyle(fontSize: 20.0,))),
                  Expanded(child: Text(player.state ?? '',style: TextStyle(fontSize: 20.0,))),
                  Expanded(child: Text(player.phoneFlechado!= null? '💘': '',style: TextStyle(fontSize: 20.0,))),
                  Expanded(child: Text(player.protegidoActivo != null? '🛡️': '',style: TextStyle(fontSize: 20.0,))),
                  SizedBox(
                     width: 60.0,  // Aquí puedes establecer el ancho del IconButton
                     height: 35.0,  // Altura si lo necesitas
                     child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _editItem(index, player),
                    ),
                  ),
                  player.phone.trim().isNotEmpty && (player.phone.trim() != '12345' && player.phone.trim() != '1234')?
                    SizedBox(
                      width: 60.0,  // Aquí puedes establecer el ancho del IconButton
                      height: 35.0,  // Altura si lo necesitas
                      child: IconButton(
                        icon: const Icon(Icons.message, color: Colors.white),
                        onPressed: () {
                          launch('sms:${player.phone}?body=${player.role}');
                          //openWhatsApp(phone: '${player.phone}', text: '${player.role}');
                        },
                        //onPressed: () => _editItem(index, player),
                      ),
                    )
                    : SizedBox(width: 60.0, height: 35.0,)
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}