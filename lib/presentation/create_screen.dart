import 'dart:convert';
import 'package:flutter/material.dart';

class AgregarJugadorScreen extends StatefulWidget {
  @override
  _AgregarJugadorScreenState createState() => _AgregarJugadorScreenState();
}

class _AgregarJugadorScreenState extends State<AgregarJugadorScreen> {
  final List<Map<String, dynamic>> jugadores = [];
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para los campos del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _posicionController = TextEditingController();

  void _agregarJugador() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        jugadores.add({
          "nombre": _nombreController.text,
          "edad": int.parse(_edadController.text),
          "telefono": _posicionController.text,
        });

        // Limpia los campos después de guardar
        _nombreController.clear();
        _edadController.clear();
        _posicionController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jugador agregado exitosamente')),
      );
    }
  }

  void _irASiguientePantalla() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaJugadoresScreen(jugadores: jugadores),
      ),
    );
  }

  void _exportarComoJSON() {
    final jsonString = jsonEncode(jugadores);
    print("Exportando como JSON:");
    print(jsonString);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Datos exportados como JSON en consola')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Nuevo Jugador'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _exportarComoJSON,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(labelText: 'Nombre del Jugador'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _edadController,
                    decoration: InputDecoration(labelText: 'Edad'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La edad es requerida';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Introduce un número válido';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _posicionController,
                    decoration: InputDecoration(labelText: 'Telefono'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefono es requerido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _agregarJugador,
                    child: Text('Agregar Jugador'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _irASiguientePantalla,
                    child: Text('Ver Lista de Jugadores'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: jugadores.length,
                itemBuilder: (context, index) {
                  final jugador = jugadores[index];
                  return ListTile(
                    title: Text(jugador['nombre']),
                    subtitle: Text(
                        'Edad: ${jugador['edad']} - Teléfono: ${jugador['telefono']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _edadController.dispose();
    _posicionController.dispose();
    super.dispose();
  }
}

class ListaJugadoresScreen extends StatelessWidget {
  final List<Map<String, dynamic>> jugadores;

  const ListaJugadoresScreen({Key? key, required this.jugadores})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Jugadores'),
      ),
      body: jugadores.isEmpty
          ? Center(child: Text('No hay jugadores registrados'))
          : ListView.builder(
              itemCount: jugadores.length,
              itemBuilder: (context, index) {
                final jugador = jugadores[index];
                return ListTile(
                  title: Text(jugador['nombre']),
                  subtitle: Text(
                      'Edad: ${jugador['edad']} - Teléfono: ${jugador['telefono']}'),
                );
              },
            ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AgregarJugadorScreen(),
  ));
}