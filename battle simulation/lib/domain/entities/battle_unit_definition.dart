import 'package:todo_list/domain/entities/battle_unit_skill.dart';

class BattleUnitDefinitionEntity {
  final String id;
  final String name;
  final String iconKey;
  final int attack;
  final int health;
  final BattleAttackPatternKey attackPattern;
  final int? attackPatternAmount;
  final List<BattleOnHitEffectEntity> onHitEffects;
  final List<BattleTargetedSkillEntity> targetedSkills;
  final List<BattlePassiveSkillEntity> passiveSkills;

  const BattleUnitDefinitionEntity({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.attack,
    required this.health,
    this.attackPattern = BattleAttackPatternKey.front,
    this.attackPatternAmount,
    this.onHitEffects = const <BattleOnHitEffectEntity>[],
    this.targetedSkills = const <BattleTargetedSkillEntity>[],
    this.passiveSkills = const <BattlePassiveSkillEntity>[],
  });

  BattleUnitDefinitionEntity copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? attack,
    int? health,
    BattleAttackPatternKey? attackPattern,
    int? attackPatternAmount,
    List<BattleOnHitEffectEntity>? onHitEffects,
    List<BattleTargetedSkillEntity>? targetedSkills,
    List<BattlePassiveSkillEntity>? passiveSkills,
  }) {
    return BattleUnitDefinitionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      attack: attack ?? this.attack,
      health: health ?? this.health,
      attackPattern: attackPattern ?? this.attackPattern,
      attackPatternAmount: attackPatternAmount ?? this.attackPatternAmount,
      onHitEffects: onHitEffects ?? this.onHitEffects,
      targetedSkills: targetedSkills ?? this.targetedSkills,
      passiveSkills: passiveSkills ?? this.passiveSkills,
    );
  }
}
