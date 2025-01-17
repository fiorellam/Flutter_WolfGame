import 'dart:async';
import 'package:flutter/material.dart';
import 'package:game_wolf/domain/phase.dart';
import 'package:game_wolf/domain/phases_by_level.dart';
import 'package:game_wolf/domain/player.dart';
import 'package:game_wolf/services/phases_assign.dart';
//import 'package:game_wolf/presentation/widgets/dropdown_players.dart';

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
  List<Phase> dayPhases = [];
  List<Phase> nightPhases = [];
  int currentPhaseIndex = 0;
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
    });

  }

  void _goToNextPhase() {
     setState(() {
      // Obtener las fases actuales (día o noche)
      List<Phase> currentPhases = isDay ? dayPhases : nightPhases;
      /*
      if (isDay && dayPhases[currentPhaseIndex].name == 'Asamblea'){
        if (lobos[Vivo] == !lobos[Vivo])
          lobos -> gana
        if (lobos[Vivo] == 0)
          aldeanos -> gana
        
      }
      */
      // Avanzar al siguiente índice dentro de las fases actuales
      if (currentPhaseIndex < currentPhases.length - 1) {
        currentPhaseIndex++;
      } else {
        // Cambiar entre día y noche y reiniciar el índice
        isDay = !isDay;
        currentPhaseIndex = 0;
        if (isDay == false) {
            contador++;
        }
      }

      // Actualizar el estado del juego
      gameState = isDay ? dayPhases[currentPhaseIndex].name : nightPhases[currentPhaseIndex].name;
      
      if (isDay && dayPhases[currentPhaseIndex].name == 'Asamblea') {
        // Buscar el primer jugador con estado 'Seleccionado'
        final Player? selectedPlayer = widget.selectedPlayers.firstWhere(
          (player) => player.state == 'Seleccionado', // Si no hay ningún jugador con este estado, devuelve null
        );

        // Asignar el estado 'Muerto' si se encontró un jugador
        if (selectedPlayer != null) {
          setState(() {
            selectedPlayer.state = 'Muerto';
          });
        } else {
          
        }
      }
      final sizeLobo = widget.selectedPlayers
        .where((player) => (player.state == 'Vivo' || player.state == 'Seleccionado') && player.role == "Lobo")
        .length;
      final sizeNoLobos = widget.selectedPlayers
        .where((player) => (player.state == 'Vivo' || player.state == 'Seleccionado') && player.role != "Lobo")
        .length;
      if (sizeLobo == sizeNoLobos || sizeLobo > sizeNoLobos){
        _whoWon(text: "Ganaron Lobos!!");
      }else{
        if (sizeLobo == 0){
          _whoWon(text: "Ganaron Aldeanos!!");
        }
      }
      if (isDay && dayPhases[currentPhaseIndex].name == 'Eleccion Sheriff') {
        _turnSheriff();
      }
      if (isDay && dayPhases[currentPhaseIndex].name == 'Nominacion') {
        _showTemporizador();
      }
      if (!isDay && nightPhases[currentPhaseIndex].name == 'Lobos') {
        _turnLobos();
      }

      if (!isDay && nightPhases[currentPhaseIndex].name == 'Curandero') {
        _turnCurandero();
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
                    .where((player) => player.state?.toLowerCase() != 'Muerto') // Excluir jugadores Muertos
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
                    .where((player) => player.state?.toLowerCase() != 'Muerto' && player.state?.toLowerCase() != 'Sheriff') // Excluir jugadores Muertos
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
    int remainingSeconds = totalSeconds;
    Timer? timer;
    Player? selectedPlayer; // Jugador seleccionado actualmente

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
                  Navigator.of(context).pop();
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
                    .where((player) => player.state?.toLowerCase() != 'Muerto') // Excluir jugadores Muertos
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
                if (timer != null) timer?.cancel(); // Cancelar el temporizador
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState((){
                  selectedPlayer?.state = 'Muerto';
                  Navigator.of(context).pop();
                });
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
                    .where((player) => player.state?.toLowerCase() != 'Muerto') // Excluir jugadores Muertos
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
                    .where((player) => player.curado?.toLowerCase() != '2') // Excluir jugadores Muertos
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
                if (selectedPlayer?.curado == null){
                  setState(() {
                    selectedPlayer?.curado = '1';
                    selectedPlayer?.state = 'Vivo';
                    Navigator.of(context).pop();
                  });
                }
                else {
                  if (selectedPlayer?.curado == '1'){
                    setState(() {
                      selectedPlayer?.curado = '2';
                      selectedPlayer?.state = 'Vivo';
                      Navigator.of(context).pop();
                    });
                  }
                  else {
                    setState((){
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
                    .where((player) => player.state?.toLowerCase() != 'Muerto') // Excluir jugadores Muertos
                    .map((player) {
                    return DropdownMenuItem<Player>(
                      value: player,
                      child: Text("${player.name} ${player.lastName} - ${player.role}"),
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

  //Modal Bruja
  void _turnBruja() {

    Player? selectedPlayer; // Jugador seleccionado actualmente

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
                    .where((player) => player.state?.toLowerCase() != 'Muerto') // Excluir jugadores Muertos
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
                if (selectedPlayer?.role == 'Lobo'){
                  setState(() {
                    selectedPlayer?.state = 'Muerto';
                    Navigator.of(context).pop();
                  });
                }
                else {
                  setState((){
                    Navigator.of(context).pop();
                  });
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void _whoWon({String? text}) {

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
        title: Text('JUEGO LOBO - Nivel: ${widget.level}'),
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
                //Boton siguiente fase
                FilledButton(
                  onPressed: _goToNextPhase,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0)
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                  child: Text("Siguiente Fase"),
                  
                )
              ],
            ),
            _buildPlayerListView(),
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
                          '${index + 1}',
                          style: new TextStyle(
                            fontSize: 20.0,
                          ))),
                  Expanded(
                      child: Text(
                          '${player.name} ${player.lastName}',
                          style: new TextStyle(
                            fontSize: 20.0,
                          ))),
                  Expanded(
                      child: Text(
                          player.role,
                          style: new TextStyle(
                            fontSize: 20.0,
                          ))),
                  Expanded(
                      child: Text(
                          player.secondaryRol ?? '',
                          style: new TextStyle(
                            fontSize: 20.0,
                          ))),
                  Expanded(
                      child: Text(
                          player.state ?? '',
                          style: new TextStyle(
                            fontSize: 20.0,
                          ))),
                  SizedBox(
                     width: 60.0,  // Aquí puedes establecer el ancho del IconButton
                     height: 35.0,  // Altura si lo necesitas
                     child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _editItem(index, player),
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
}
