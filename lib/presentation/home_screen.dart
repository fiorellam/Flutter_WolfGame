import 'package:flutter/material.dart';
import 'package:game_wolf/presentation/widgets/dropdown_levels.dart';
import 'package:game_wolf/presentation/widgets/search_bar2.dart';
class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  String _selectedValue = "Principiante"; //Valor inicial
  List<String> levelsList = ["Principiante", "Intermedio", "Avanzado", "Pro" ];
  List<String> _items = ['Fiorella Rodriguez', 'Jesus Miguel Armenta', 'Eduardo Flores', 'Cindy']; // Lista de jugadores
  List<String> _filteredItems = []; // Lista que se actualizará con los elementos filtrados
  Set<String> _selectedItems = {}; // Conjunto para almacenar los elementos seleccionados

  @override
  void initState() {
    super.initState();
    _filteredItems = _items; // Inicializa la lista de items filtrados con todos los elementos
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
      _filteredItems = filteredItems; // Actualiza la lista con los elementos filtrados
    });
  }

  // Método que maneja la selección de un item
  // void _onSelectItem(String selectedItem) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Seleccionaste'),
  //         content: Text(selectedItem),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text('Cerrar'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

   // Método que maneja la selección de un item
  void _onSelectItem(String selectedItem) {
    setState(() {
      if (_selectedItems.contains(selectedItem)) {
        _selectedItems.remove(selectedItem); // Si ya está seleccionado, lo deseleccionamos
      } else {
        _selectedItems.add(selectedItem); // Si no está seleccionado, lo seleccionamos
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Jugadores'),
      ),
      body: Column(
        children: [
          // Usamos el widget SearchBar
          SearchBar2(items: _items, onFilter: _onFilter),
          const SizedBox(height: 20),
            Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length, // Muestra los elementos filtrados
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = _selectedItems.contains(item); // Verifica si el item está seleccionado
                return ListTile(
                  leading: Icon (
                    isSelected ? Icons.check_circle : Icons.check_circle_outline, // Muestra el icono dependiendo de la selección
                      color: isSelected ? Colors.green : Colors.grey,
                   ), // Cambia el color según el estado de selección,
                  title: Text(_filteredItems[index]),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Telefono: 6461778925"),
                      // Text("Rol: Lobo")
                    ],
                  ),
                  subtitle: Text("6461772925"),
                  onTap: () => _onSelectItem(_filteredItems[index]), // Maneja la selección
                );
              },
            ),
          ),
          DropdownLevel(items: levelsList, onChanged: _handleDropdownLevelChange),   
          Text("Valor seleccionado: $_selectedValue", style: const TextStyle(fontSize: 18)),       
        ],
      ),
    );
  }
}
