import 'package:todo_list/domain/entities/battle_unit_skill.dart';

class BattleUnitDefinitionEntity {
  final String id;
  final String name;
  final String shortCode;
  final String iconKey;
  final int attack;
  final int health;
  final List<BattleUnitSkillEntity> skills;

  const BattleUnitDefinitionEntity({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.iconKey,
    required this.attack,
    required this.health,
    required this.skills,
  });

  BattleUnitDefinitionEntity copyWith({
    String? id,
    String? name,
    String? shortCode,
    String? iconKey,
    int? attack,
    int? health,
    List<BattleUnitSkillEntity>? skills,
  }) {
    return BattleUnitDefinitionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      iconKey: iconKey ?? this.iconKey,
      attack: attack ?? this.attack,
      health: health ?? this.health,
      skills: skills ?? this.skills,
    );
  }
}
