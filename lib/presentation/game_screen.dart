import 'package:flutter/material.dart';
import 'package:game_wolf/domain/player.dart';

class GameScreen extends StatefulWidget {
  final List<Player> selectedPlayers;

  GameScreen({super.key, required this.selectedPlayers});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JUEGO LOBO'),
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0), //16 px en todos los lados
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildPlayerListView(),
          ],
        ),
      ),
    );
  }

  // final List<Map<String, dynamic>> data = [
  //   {"id": "3","name": "Miguel", "rol": "Aldeano", "state": "vivo"},
  //   {"id": "10","name": "Fiorella", "rol": "Aldeano", "state": "vivo"},
  //   {"id": "1","name": "Lalo", "rol": "Bruja", "state": "vivo"},
  //   {"id": "4","name": "Cindy", "rol": "Lobo", "state": "vivo"},
  //   {"id": "6","name": "Jugador_1", "rol": "Curandero", "state": "muerto"},
  //   {"id": "8","name": "Jugador_2", "rol": "Lobo", "state": "vivo"},
  //   {"id": "2","name": "Jugador_3", "rol": "Vidente", "state": "vivo"},
  //   {"id": "5","name": "Jugador_4", "rol": "Lobo", "state": "muerto"},
  //   {"id": "7","name": "Jugador_5", "rol": "Granjero", "state": "vivo"},
  //   {"id": "9","name": "Jugador_6", "rol": "Aldeano", "state": "vivo"},
  //   {"id": "11","name": "Jugador_7", "rol": "Aldeano", "state": "muerto"},
  // ];
  //Mostrar los datos
  Widget _buildPlayerListView() {
    return Expanded(
      child: ListView.builder(
        itemCount: widget.selectedPlayers.length,
        itemBuilder: (context, index) {
          final player = widget.selectedPlayers[index];

          // Condición para resaltar el renglón en rojo
          // para hacer los cambios dinamicamente
          final isAlive = player.state.toLowerCase() == "vivo";

          return Card(
            color: isAlive ? Colors.white : Colors.red.shade100,
            margin: EdgeInsets.all(4),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //mostrar los datos en columnas
                children: [
                  Expanded(
                      child: Text(player.id.toString())),
                  Expanded(
                      child: Text(player.name)),
                  Expanded(
                      child: Text(player.role)),
                  Expanded(
                      child: Text(player.state)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
