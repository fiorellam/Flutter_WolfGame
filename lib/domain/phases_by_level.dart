import 'package:game_wolf/domain/phase.dart';

class PhasesByLevel{
    final String level;
    final List dia;
    final List noche;
    final List jerarquia;

    PhasesByLevel({required this.level, required this.dia, required this.noche, required this.jerarquia});

    factory PhasesByLevel.fromJson(Map<String, dynamic> json){
      return PhasesByLevel(
        level: json['level'], 
        dia: (json['dia'] as List).map((phase) => Phase.fromJson(phase)).toList(), 
        noche: (json['noche']as List).map((phase) => Phase.fromJson(phase)).toList(),
        jerarquia: (json['jerarquia'] as List).map((hierarchy) => Phase.fromJson(hierarchy)).toList()
      );
    }
}