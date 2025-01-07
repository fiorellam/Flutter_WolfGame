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
          final isAlive = player.state.toLowerCase() == "vivo";

          return Card(
            color: isAlive ? Colors.green.shade50 : Colors.red.shade200,
            margin: EdgeInsets.all(4),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
