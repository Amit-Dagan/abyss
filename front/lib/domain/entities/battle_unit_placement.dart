import 'package:todo_list/domain/entities/battle_enums.dart';

class BattleUnitPlacementEntity {
  final ArmySide armySide;
  final String definitionId;
  final int row;
  final int column;

  const BattleUnitPlacementEntity({
    required this.armySide,
    required this.definitionId,
    required this.row,
    required this.column,
  });

  BattleUnitPlacementEntity copyWith({
    ArmySide? armySide,
    String? definitionId,
    int? row,
    int? column,
  }) {
    return BattleUnitPlacementEntity(
      armySide: armySide ?? this.armySide,
      definitionId: definitionId ?? this.definitionId,
      row: row ?? this.row,
      column: column ?? this.column,
    );
  }
}
