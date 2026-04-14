import 'package:todo_list/domain/entities/battle_enums.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';

class BattleUnitStateEntity {
  final String instanceId;
  final String definitionId;
  final String displayName;
  final ArmySide armySide;
  final int row;
  final int column;
  final int currentHealth;
  final int maxHealth;
  final int currentAttack;
  final bool hasTaunt;
  final bool isStunned;
  final bool isEnraged;
  final int poisonStacks;
  final int fireStacks;

  const BattleUnitStateEntity({
    required this.instanceId,
    required this.definitionId,
    required this.displayName,
    required this.armySide,
    required this.row,
    required this.column,
    required this.currentHealth,
    required this.maxHealth,
    required this.currentAttack,
    required this.hasTaunt,
    required this.isStunned,
    required this.isEnraged,
    required this.poisonStacks,
    required this.fireStacks,
  });

  factory BattleUnitStateEntity.fromRuntime({
    required String instanceId,
    required BattleUnitDefinitionEntity definition,
    required ArmySide armySide,
    required int row,
    required int column,
    required int currentHealth,
    required int currentAttack,
    required bool hasTaunt,
    required bool isStunned,
    required bool isEnraged,
    required int poisonStacks,
    required int fireStacks,
  }) {
    return BattleUnitStateEntity(
      instanceId: instanceId,
      definitionId: definition.id,
      displayName: definition.name,
      armySide: armySide,
      row: row,
      column: column,
      currentHealth: currentHealth,
      maxHealth: definition.health,
      currentAttack: currentAttack,
      hasTaunt: hasTaunt,
      isStunned: isStunned,
      isEnraged: isEnraged,
      poisonStacks: poisonStacks,
      fireStacks: fireStacks,
    );
  }
}
