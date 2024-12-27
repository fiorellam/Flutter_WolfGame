import 'package:flutter/material.dart';
class DropdownLevel extends StatefulWidget {
  // const DropdownLevel({super.key});

  final List<String> items;
  final Function(String) onChanged;

  const DropdownLevel({
    super.key,
    required this.items,
    required this.onChanged
  });

  @override
  State<DropdownLevel> createState() => _DropdownLevelState();
}

class _DropdownLevelState extends State<DropdownLevel> {
  String? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedItem,
      hint: const Text('Selecciona el nivel'),
      onChanged: (String? newValue){
        setState(() {
          _selectedItem = newValue;
        });
        widget.onChanged(newValue!);
      },
      items: widget.items.map((String item){
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }
}