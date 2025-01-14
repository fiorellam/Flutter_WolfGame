import 'package:flutter/material.dart';
import 'package:game_wolf/domain/phase.dart';
import 'package:game_wolf/domain/phases_by_level.dart';
import 'package:game_wolf/domain/player.dart';
import 'package:game_wolf/services/phases_assign.dart';

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

  bool isDay = true;
  String gameState = "Lobos Turno";
  List<Phase> dayPhases = [];
  List<Phase> nightPhases = [];
  int currentPhaseIndex = 0;

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

      // Avanzar al siguiente índice dentro de las fases actuales
      if (currentPhaseIndex < currentPhases.length - 1) {
        currentPhaseIndex++;
      } else {
        // Cambiar entre día y noche y reiniciar el índice
        isDay = !isDay;
        currentPhaseIndex = 0;
      }

      // Actualizar el estado del juego
      gameState = isDay ? dayPhases[currentPhaseIndex].name : nightPhases[currentPhaseIndex].name;
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
          final isAlive = player.state?.toLowerCase() == "vivo";

          return Card(
            color: isAlive ? const Color.fromARGB(147, 49, 220, 98) : Colors.red.shade300,
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
