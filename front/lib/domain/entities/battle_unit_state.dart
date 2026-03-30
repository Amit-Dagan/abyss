import 'package:todo_list/domain/entities/battle_enums.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';

class BattleUnitStateEntity {
  final String instanceId;
  final String definitionId;
  final String shortCode;
  final String displayName;
  final ArmySide armySide;
  final int row;
  final int column;
  final int currentHealth;
  final int maxHealth;

  const BattleUnitStateEntity({
    required this.instanceId,
    required this.definitionId,
    required this.shortCode,
    required this.displayName,
    required this.armySide,
    required this.row,
    required this.column,
    required this.currentHealth,
    required this.maxHealth,
  });

  factory BattleUnitStateEntity.fromRuntime({
    required String instanceId,
    required BattleUnitDefinitionEntity definition,
    required ArmySide armySide,
    required int row,
    required int column,
    required int currentHealth,
  }) {
    return BattleUnitStateEntity(
      instanceId: instanceId,
      definitionId: definition.id,
      shortCode: definition.shortCode,
      displayName: definition.name,
      armySide: armySide,
      row: row,
      column: column,
      currentHealth: currentHealth,
      maxHealth: definition.health,
    );
  }
}
