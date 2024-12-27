import 'package:flutter/material.dart';
class SearchBar2 extends StatefulWidget {

  final List<String> items; //Lista de items a filtrar
  final Function(List<String>) onFilter; // Callback para devolver los items filtrados
  //TODO: Cambiar <String> por el tipo de objeto ya sea Player o Personaje

  const SearchBar2({
    super.key,
    required this.items,
    required this.onFilter
  });

  @override
  _SearchBar2State createState() => _SearchBar2State(); 
}

class _SearchBar2State extends State<SearchBar2>{
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSearchResults); // Escucha cambios en el texto
  }

  //Método para filtrar los resultados según la busqueda
  void _filterSearchResults(){
    final query = _searchController.text.toLowerCase();
    final filteredItems = widget.items
      .where((item) => item.toLowerCase().contains(query))
      .toList();
    widget.onFilter(filteredItems); // Llamar al callback con los resultados filtrados
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController, //Asocia el controlador con el TextField
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade300,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        hintText: "Busca a un jugador",
        suffixIcon: const Icon(Icons.search),
        // suffixIconColor: Colors.pink
      ),
    );
  }
  @override
  void dispose() {
    _searchController.removeListener(_filterSearchResults); // Elimina el listener cuando el widget se destruye
    _searchController.dispose(); // Libera el controlador
    super.dispose();
  }
}

