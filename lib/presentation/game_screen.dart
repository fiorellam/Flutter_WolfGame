import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:game_wolf/domain/phase.dart';
import 'package:game_wolf/domain/phases_by_level.dart';
import 'package:game_wolf/domain/player.dart';
import 'package:game_wolf/services/phases_assign.dart';
//import 'package:game_wolf/presentation/widgets/dropdown_players.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:flutter_sms/flutter_sms.dart';

class GameScreen extends StatefulWidget {
  final List<Player> selectedPlayers;
  final String level;

  const GameScreen({super.key, 
    required this.selectedPlayers,
    required this.level
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int contador = 0;
  bool isDay = true;
  String gameState = "Lobos Turno";
  String nextStatePhase = ''; 
  List<Phase> dayPhases = [];
  List<Phase> nightPhases = [];
  int currentPhaseIndex = 0;
  bool hasSheriffBeenSelected = false; //Controla si el sheriff ha sido seleccionado
  bool hasCupidoBeenSelected = false; //Controla si cupido ya paso su turno
  List<String> recordActions = ['DIA 1'];
  int dayCounter = 1;
  int nightCounter = 0;
  int curanderoTimesBeenSaved = 0;
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

    setState(() {
      dayPhases = levelPhases.dia.cast<Phase>();
      nightPhases = levelPhases.noche.cast<Phase>();
      gameState = isDay ? dayPhases[0].name : nightPhases[0].name; // Inicializar el juego
      nextStatePhase = dayPhases[1].name;
    });

    // Turno para Cupido
    if (isDay && levelPhases.level != 'Principiante' && !hasCupidoBeenSelected) {
      _turnCupido();
      hasCupidoBeenSelected = true;
    }
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
        if (isDay == false) {
            contador++;
            nightCounter++;
            recordActions.add('NOCHE $nightCounter');
        } 
        if(isDay){
          dayCounter++;
          recordActions.add('DIA $dayCounter');
        }
      }

       // Actualizar el estado del juego (fase actual)
      gameState = isDay ? dayPhases[currentPhaseIndex].name : nightPhases[currentPhaseIndex].name;
      
      if (isDay && dayPhases[currentPhaseIndex].name == 'Asamblea') {
        Player? selectedPlayer; 
        Player? selectedPlayer2;
        try{
        // Buscar el primer jugador con estado 'Seleccionado'
          selectedPlayer = widget.selectedPlayers.firstWhere(
          (player) => player.state == 'Seleccionado',);
          if (selectedPlayer?.flechado != null){
            selectedPlayer2 = widget.selectedPlayers.firstWhere(
            (player) => selectedPlayer?.phone == player.flechado);
          }
        } catch (e) {
          selectedPlayer = null;
        }

        if(selectedPlayer?.protegidoActivo == true || selectedPlayer2?.protegidoActivo == true){
          if(selectedPlayer?.flechado != null){
            setState(() {
              selectedPlayer?.state = 'Vivo';
              selectedPlayer2?.state = 'Vivo';
              String action = 'Se salvaron ${selectedPlayer?.role} - ${selectedPlayer?.name} y ${selectedPlayer2?.role} - ${selectedPlayer2?.name }';
              recordActions.add(action);
            });
          } else {
            setState(() {
              selectedPlayer?.state = 'Vivo';
              String action = 'Se salvo ${selectedPlayer?.role} - ${selectedPlayer?.name}';
              recordActions.add(action);
            });
          }
        } else{
          // Asignar el estado 'Muerto' si se encontró un jugador
          if (selectedPlayer != null) {
            if(selectedPlayer?.flechado == null) {
              setState(() {
                selectedPlayer?.state = 'Muerto';
                String action = 'Mataron a ${selectedPlayer?.role} - ${selectedPlayer?.name}';
                recordActions.add(action);
              });
            } else {
              setState(() {
                selectedPlayer?.state = 'Muerto';
                selectedPlayer2?.state = 'Muerto';
                String action = 'Mataron a ${selectedPlayer?.role} - ${selectedPlayer?.name} y ${selectedPlayer2?.role} - ${selectedPlayer2?.name}';
                recordActions.add(action);
              });
            }
          } else {
            
          }
        }
      }
      final sizeLobo = widget.selectedPlayers
        .where((player) => (player.state == 'Vivo' || player.state == 'Seleccionado') && player.role == "Lobo")
        .length;
      final sizeNoLobos = widget.selectedPlayers
        .where((player) => (player.state == 'Vivo' || player.state == 'Seleccionado') && player.role != "Lobo")
        .length;
      if (sizeLobo == sizeNoLobos || sizeLobo > sizeNoLobos){
        _whoWonDialog(text: "Ganaron Lobos!!");
      }else{
        if (sizeLobo == 0){
          _whoWonDialog(text: "Ganaron Aldeanos!!");
        }
      }

      // Obtener la siguiente fase
      if (currentPhaseIndex < currentPhases.length - 1) {
        nextStatePhase = isDay ? dayPhases[currentPhaseIndex + 1].name : nightPhases[currentPhaseIndex + 1].name;
      } else {
        // Si estamos en la última fase de un ciclo (día o noche), la siguiente fase será la del ciclo opuesto (día o noche)
        nextStatePhase = isDay ? nightPhases[0].name : dayPhases[0].name;
      }
      // Actualizar el estado del juego
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
        //for (var i = 0; i < 2; i++){
        Player? selectedPlayer;
        //para saber la longitud
        final sizeProtector = widget.selectedPlayers
          .where((player) => player.state == 'Vivo' && player.role == 'Protector')
          .length;
        try{
          // Buscar el primer jugador con estado 'Seleccionado'
          selectedPlayer = widget.selectedPlayers.firstWhere(
          (player) => player.protegidoActivo == true,);
          setState((){
            selectedPlayer?.protegidoActivo = false;
          });
        } catch (e) {
          selectedPlayer = null;
        }
        print('Longitud de Protector ${sizeProtector}');
        _turnProtector(sizeProtector);
        //}
      }

      if (!isDay && nightPhases[currentPhaseIndex].name == 'Lobo') {
        _turnLobos();
      }

      if (!isDay && nightPhases[currentPhaseIndex].name == 'Curandero') {
        List<Player> curanderos = List<Player>.from(widget.selectedPlayers.where((player) => player.role == 'Curandero'));
        if(curanderos.isNotEmpty && curanderos[0].state != 'Muerto'){
            // Aquí colocas el código para realizar la acción de curar, si es necesario
          _turnCurandero();
        } else {
          setState(() {
            //TODO: saltar a las fases siguientes si el personaje con un rol especifico y unico ya murio
            // currentPhaseIndex++;
            // gameState = isDay ? dayPhases[currentPhaseIndex].name : nightPhases[currentPhaseIndex].name;
            // nextStatePhase = isDay ? dayPhases[currentPhaseIndex + 1].name : nightPhases[currentPhaseIndex + 1].name;
          });
        }
      }

      if (!isDay && nightPhases[currentPhaseIndex].name == 'Vidente') {
        _turnVidente();
      }

      if (!isDay && nightPhases[currentPhaseIndex].name == 'Bruja') {
        _turnBruja();
      }
    });
  }

  void _editItem(int index, Player player) {
    final TextEditingController secondaryRolController = 
      TextEditingController(text: player.secondaryRol ?? '');
    final TextEditingController stateController = 
      TextEditingController(text: player.state);
    final TextEditingController numberSeatController = 
      TextEditingController(text: player.numberSeat);
    final TextEditingController roleController = 
      TextEditingController(text: player.role);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar campos'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: secondaryRolController,
                  decoration: const InputDecoration(labelText: 'Rol Secundario'),
                ),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                TextField(
                  controller: numberSeatController,
                  decoration: const InputDecoration(labelText: 'No. Asiento'),
                ),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  player.secondaryRol = secondaryRolController.text;
                  player.state = stateController.text;
                  player.numberSeat = numberSeatController.text;
                  player.role = roleController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  //Modal lobos
  void _turnSheriff() {

    Player? selectedPlayer; // Jugador seleccionado actualmente

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: const Text("Eleccion Sheriff"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: widget.selectedPlayers
                    .where((player) => player.state?.toLowerCase() != 'muerto') // Excluir jugadores Muertos
                    .map((player) {
                    return DropdownMenuItem<Player>(
                      value: player,
                      child: Text("${player.name} ${player.lastName}"),
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState((){
                  selectedPlayer?.secondaryRol = 'Sheriff';
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

  void _turnAyudante() {

    Player? selectedPlayer; // Jugador seleccionado actualmente

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: const Text("Lobos"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: widget.selectedPlayers
                    .where((player) => player.state?.toLowerCase() != 'muerto' && player.state?.toLowerCase() != 'Sheriff') // Excluir jugadores Muertos
                    .map((player) {
                    return DropdownMenuItem<Player>(
                      value: player,
                      child: Text("${player.name} ${player.lastName}"),
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState((){
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
          title: const Text("Cuenta Regresiva"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Iniciar el temporizador
              timer ??= Timer.periodic(const Duration(seconds: 1), (Timer t) {
                if (remainingSeconds > 0) {
                  setState(() {
                    remainingSeconds--;
                  });
                } else {
                  t.cancel();
                  // Navigator.of(context).pop();
                  // _randomPlayerToKill();
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
                    return DropdownMenuItem<Player>(
                      value: player,
                      child: Text("${player.name} ${player.lastName}"),
                    );
                  }).toList(),
                  onChanged: (Player? newValue) {
                    setState(() {
                      selectedPlayer = newValue;
                    });
                  },
                ),
                ElevatedButton(onPressed:() {
                  _randomPlayerToKill();
                  Navigator.of(context).pop();
                  }, child: Text("Matar al azar"))
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
                if (selectedPlayer?.flechado != null){
                  selectedPlayer2 = widget.selectedPlayers.firstWhere(
                  (player) => selectedPlayer?.phone == player.flechado);
                  
                  if ((selectedPlayer2?.protegidoActivo == true)){
                    setState((){
                      String action = 'En la nominacion se eligio para matar a ${selectedPlayer?.role} - ${selectedPlayer?.name} pero esta protegido';
                      recordActions.add(action);
                      Navigator.of(context).pop();
                    });
                  } else {
                    setState((){
                      String action = 'En la nominacion se eligio para matar a ${selectedPlayer?.role} - ${selectedPlayer?.name} que a su vez mataron a ${selectedPlayer2?.role} - ${selectedPlayer2?.name} por estar enamorado';
                      recordActions.add(action);
                      selectedPlayer?.state = 'Muerto';
                      selectedPlayer2?.state = 'Muerto';
                      Navigator.of(context).pop();
                    });
                  }
                } else {
                  setState((){
                    String action = 'En la nominacion se eligio para matar a ${selectedPlayer?.role} - ${selectedPlayer?.name}';
                    recordActions.add(action);
                    selectedPlayer?.state = 'Muerto';
                    Navigator.of(context).pop();
                  });
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
    if(playersAlive.isNotEmpty){
      Random random = Random();
      int indexAleatorio = random.nextInt(playersAlive.length);

      //TODO: Falta que solo se puedan seleccionar jugadores que sigan vivos
      //Obtener player al azar
      Player playerSelectedToKill = playersAlive[indexAleatorio];

      //Cambiar su estado a muerto
      // Cambiar su estado a "muerto"
      setState(() {
        // Encontrar el jugador correspondiente en la lista original
        Player playerToUpdate = widget.selectedPlayers.firstWhere(
          (player) => player == playerSelectedToKill,
          //  Maneja el caso si no se encuentra el jugador
        );

        // if (playerToUpdate) {
          playerToUpdate.state = "Muerto"; // Cambiar el estado a "muerto"
          String action = 'En la pirinola murió ${playerSelectedToKill.role} - ${playerSelectedToKill.name}';
          recordActions.add(action);
        // }
      });
    }
    else{
      showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mensaje Importante'),
          content: Text('Ya no hay mas jugadores para matar'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Cerrar el AlertDialog cuando se presione "Cerrar"
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
    }
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
          title: const Text("Lobos"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: widget.selectedPlayers
                    .where((player) => (player.state?.toLowerCase() != 'muerto' && player.protegidoActivo != true)) // Excluir jugadores Muertos
                    .map((player) {
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState((){
                  String action = 'Lobos seleccionaron a ${selectedPlayer?.role} - ${selectedPlayer?.name }';
                  recordActions.add(action);
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
    Player? _getRolePlayer(String roleName){
    Player? player ;
        try{
        // Buscar el primer jugador con estado 'Seleccionado'
          player = widget.selectedPlayers.firstWhere(
          (player) => player.role == roleName,
          //  Maneja el caso si no se encuentra el jugador
        );
        } catch (e) {
          player = null;
        }
      return player;
  }
    //Modal Curandero
  void _turnCurandero() {

    Player? selectedPlayer; // Jugador seleccionado actualmente

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: const Text("Curandero"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: widget.selectedPlayers
                    .where((player) => player.curado != 2) // Excluir jugadores Muertos
                    .map((player) {
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
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
                String action = "Curanderos seleccionaron a ${selectedPlayer?.role} - ${selectedPlayer?.name}";
                recordActions.add(action);
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  //Modal Protector
  void _turnProtector(int numSize) {

    Player? selectedPlayer; // Jugador seleccionado actualmente

    showDialog(
      context: context,
      barrierDismissible: false, // Impide cerrar tocando fuera del diálogo
      builder: (context) {
        return AlertDialog(
          title: const Text("Protector"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: widget.selectedPlayers
                    .where((player) => player.protegido != 2 && player.state?.toLowerCase() != 'muerto') // Excluir jugadores Muertos
                    .map((player) {
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
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
                String action = "Protector selecciono a ${selectedPlayer?.role} - ${selectedPlayer?.name}";
                recordActions.add(action);
                print(numSize);
                if(numSize > 1){
                  _turnProtector(numSize - 1);
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
          title: const Text("Cupido"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione primer jugador"),
                  value: selectedPlayer1,
                  items: widget.selectedPlayers
                    .where((player) => player.protegido != 2) // Excluir jugadores Muertos
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
                  items: widget.selectedPlayers
                    .where((player) => player.protegido != 2) // Excluir jugadores Muertos
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedPlayer1?.flechado = selectedPlayer2?.phone;
                  selectedPlayer2?.flechado = selectedPlayer1?.phone;
                  Navigator.of(context).pop();
                });
                String action = "Cupido selecciono a ${selectedPlayer1?.role} - ${selectedPlayer1?.name} y ${selectedPlayer2?.role} - ${selectedPlayer2?.name}";
                recordActions.add(action);
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
          title: const Text("Vidente"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: widget.selectedPlayers
                    .where((player) => player.state?.toLowerCase() != 'muerto') // Excluir jugadores Muertos
                    .map((player) {
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState((){
                  String action = "Vidente quiso saber el rol de ${selectedPlayer?.role} - ${selectedPlayer?.name}";
                  recordActions.add(action);
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
          title: const Text("Bruja"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown para seleccionar jugador
                DropdownButton<Player>(
                  hint: const Text("Seleccione un jugador"),
                  value: selectedPlayer,
                  items: widget.selectedPlayers
                    .where((player) => player.state?.toLowerCase() != 'muerto') // Excluir jugadores Muertos
                    .map((player) {
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                if (selectedPlayer?.flechado != null){
                  selectedPlayer2 = widget.selectedPlayers.firstWhere(
                  (player) => selectedPlayer?.phone == player.flechado);
                }
                //optimizar este bloque
                //revisamos si esta protegido por lo cual si esta protegido y es lobo no puede matarlo
                if((selectedPlayer?.protegidoActivo == true || selectedPlayer2?.protegidoActivo == true) && selectedPlayer?.role == 'Lobo'){
                  setState((){
                    String action = 'Bruja descubrio a ${selectedPlayer?.role} - ${selectedPlayer?.name} pero no pudo matarlo porque esta protegido por ${selectedPlayer2?.role} - ${selectedPlayer2?.name}';
                    recordActions.add(action);
                    Navigator.of(context).pop();
                  });
                } else{
                  if (selectedPlayer?.flechado != null && selectedPlayer?.role == 'Lobo'){
                    setState(() {
                      selectedPlayer?.state = 'Muerto';
                      selectedPlayer2?.state = 'Muerto';
                      String action = 'Bruja descubrio a ${selectedPlayer?.role} - ${selectedPlayer?.name} y además mato a ${selectedPlayer2?.role} - ${selectedPlayer2?.name} porque estaba enamorado';
                      recordActions.add(action);
                      Navigator.of(context).pop();
                    });
                  } else {
                    if (selectedPlayer?.role == 'Lobo'){
                      setState(() {
                        selectedPlayer?.state = 'Muerto';
                        String action = 'Bruja descubrio a ${selectedPlayer?.role} - ${selectedPlayer?.name}';
                        recordActions.add(action);
                        Navigator.of(context).pop();
                      });
                    }
                    else {
                      setState((){
                        selectedPlayer?.state = 'Muerto';
                        String action = 'Bruja no pudo matar a ${selectedPlayer?.role} - ${selectedPlayer?.name}';
                        recordActions.add(action);
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
              children: [
                Text('$text')
              ],
            );

            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Aceptar"),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('JUEGO LOBO - Nivel: ${widget.level} Daycounter: $dayCounter Night: $nightCounter #Jugadores: ${widget.selectedPlayers.length}'),
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0), //16 px en todos los lados
        child: Column(
          children: [
            //Cuadros de informacion y botón
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  color: const Color.fromARGB(255, 137, 108, 188),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text('Estado: ${isDay? 'Día' : 'Noche'}'),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  color: const Color.fromARGB(255, 137, 108, 188),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text("Estado: $gameState"),
                  ) ,
                ),
                FilledButton(
                  onPressed:(){},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0)
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                  child: Text('Poción 1'),
                  
                ),
                FilledButton(
                  onPressed: (){},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0)
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                  child: Text('Poción 2'),
                  
                ),
                //Boton siguiente fase
                FilledButton(
                  onPressed: _goToNextPhase,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0)
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                  child: Text('Siguiente Fase: $nextStatePhase'),
                  
                )
              ],
            ),
            _buildPlayerListView(),
            
        // Aquí usamos un ListView para mostrar las acciones
            Container(
              height: 100,
              child: ListView.builder(
                itemCount: recordActions.length,
                itemBuilder: (context, index) {
                  // return ListTile(
                  //   title: Text(recordActions[index]), // Mostrar cada acción en la lista
                  // );
                  return  Text(recordActions[index]); // Mostrar cada acción en la lista
                  
                },
              ),
            )
          ],
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
                  Expanded(
                      child: Text(
                          // '${index + 1}',
                          player.numberSeat ?? '',
                          style: TextStyle( fontSize: 20.0,))),
                  Expanded(
                      child: Text(
                          '${player.name} ${player.lastName}',
                          style: TextStyle(fontSize: 20.0,))),
                  // Expanded(
                  //     child: Text(
                  //         player.numberSeat ?? '',
                  //         style: TextStyle(fontSize: 20.0,))),
                  Expanded(
                      child: Text(
                          player.role,
                          style: TextStyle(fontSize: 20.0,))),
                  Expanded(
                      child: Text(
                          player.secondaryRol ?? '',
                          style: TextStyle(fontSize: 20.0,))),
                  Expanded(
                      child: Text(
                          player.state ?? '',
                          style: TextStyle(fontSize: 20.0,))),
                  SizedBox(
                     width: 60.0,  // Aquí puedes establecer el ancho del IconButton
                     height: 35.0,  // Altura si lo necesitas
                     child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _editItem(index, player),
                    ),
                  ),
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
                ],
              ),
            ),
          );
        },
      ),
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

  /*void _sendSms(String text, String phone) async{
    await sendSMS(message: "Tu rol es: $text", recipients: phone);
  }*/
}
