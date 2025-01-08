import 'package:flutter/material.dart';
import 'package:game_wolf/domain/player.dart';

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

  void _goToNextPhase() {
    setState(() {
      //Cambiar de dia a noche o viceversa
      //TODO: Esto solo va a cambiar una vez hayan terminado todos las fases
      isDay = !isDay;
      //Cambiar el estado del juego 
      //TODO: Falta traer los estados de juego dependiendo del nivel
      gameState = 'Turno Bruja';
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
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text('Estado: ${isDay? 'Día' : 'Noche'}'),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
            color: isAlive ? Colors.green.shade50 : Colors.red.shade200,
            margin: EdgeInsets.all(4),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //mostrar los datos en columnas
                children: [
                  Expanded(
                      child: Text('${index + 1}')),
                  Expanded(
                      child: Text('${player.name} ${player.lastName}')),
                  Expanded(
                      child: Text(player.role)),
                  Expanded(
                      child: Text(player.secondaryRol ?? '')),
                  Expanded(
                      child: Text(player.state ?? '')),
                  Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
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
