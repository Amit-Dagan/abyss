import 'package:todo_list/data/model/battle_unit_skill_model.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';

class BattleUnitDefinitionModel {
  final String id;
  final String name;
  final String iconKey;
  final int attack;
  final int health;
  final String attackPattern;
  final int? attackPatternAmount;
  final List<BattleOnHitEffectModel> onHitEffects;
  final List<BattleTargetedSkillModel> targetedSkills;
  final List<BattlePassiveSkillModel> passiveSkills;

  const BattleUnitDefinitionModel({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.attack,
    required this.health,
    required this.attackPattern,
    this.attackPatternAmount,
    required this.onHitEffects,
    required this.targetedSkills,
    required this.passiveSkills,
  });

  factory BattleUnitDefinitionModel.fromJson(Map<String, dynamic> json) {
    return BattleUnitDefinitionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['iconKey'] as String,
      attack: json['attack'] as int,
      health: json['health'] as int,
      attackPattern: (json['attackPattern'] as String?) ?? 'front',
      attackPatternAmount: json['attackPatternAmount'] as int?,
      onHitEffects:
          ((json['onHitEffects'] as List<dynamic>?) ?? const <dynamic>[])
              .map(
                (dynamic skillJson) => BattleOnHitEffectModel.fromJson(
                  skillJson as Map<String, dynamic>,
                ),
              )
              .toList(),
      targetedSkills:
          ((json['targetedSkills'] as List<dynamic>?) ?? const <dynamic>[])
              .map(
                (dynamic skillJson) => BattleTargetedSkillModel.fromJson(
                  skillJson as Map<String, dynamic>,
                ),
              )
              .toList(),
      passiveSkills:
          ((json['passiveSkills'] as List<dynamic>?) ?? const <dynamic>[])
              .map(
                (dynamic skillJson) => BattlePassiveSkillModel.fromJson(
                  skillJson as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  factory BattleUnitDefinitionModel.fromEntity(
    BattleUnitDefinitionEntity entity,
  ) {
    return BattleUnitDefinitionModel(
      id: entity.id,
      name: entity.name,
      iconKey: entity.iconKey,
      attack: entity.attack,
      health: entity.health,
      attackPattern: entity.attackPattern.key,
      attackPatternAmount: entity.attackPatternAmount,
      onHitEffects: entity.onHitEffects
          .map(BattleOnHitEffectModel.fromEntity)
          .toList(growable: false),
      targetedSkills: entity.targetedSkills
          .map(BattleTargetedSkillModel.fromEntity)
          .toList(growable: false),
      passiveSkills: entity.passiveSkills
          .map(BattlePassiveSkillModel.fromEntity)
          .toList(growable: false),
    );
  }

  BattleUnitDefinitionEntity toEntity() {
    return BattleUnitDefinitionEntity(
      id: id,
      name: name,
      iconKey: iconKey,
      attack: attack < 1 ? 1 : attack,
      health: health < 1 ? 1 : health,
      attackPattern: parseAttackPatternKey(attackPattern),
      attackPatternAmount: attackPatternAmount == null
          ? null
          : (attackPatternAmount! < 1 ? 1 : attackPatternAmount),
      onHitEffects: onHitEffects
          .map((BattleOnHitEffectModel effect) => effect.toEntity())
          .toList(growable: false),
      targetedSkills: targetedSkills
          .map((BattleTargetedSkillModel skill) => skill.toEntity())
          .toList(growable: false),
      passiveSkills: passiveSkills
          .map((BattlePassiveSkillModel skill) => skill.toEntity())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconKey': iconKey,
      'attack': attack,
      'health': health,
      'attackPattern': attackPattern,
      if (attackPatternAmount != null)
        'attackPatternAmount': attackPatternAmount,
      'onHitEffects': onHitEffects
          .map((BattleOnHitEffectModel effect) => effect.toJson())
          .toList(),
      'targetedSkills': targetedSkills
          .map((BattleTargetedSkillModel skill) => skill.toJson())
          .toList(),
      'passiveSkills': passiveSkills
          .map((BattlePassiveSkillModel skill) => skill.toJson())
          .toList(),
    };
  }
}
