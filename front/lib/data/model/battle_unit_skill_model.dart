import 'package:todo_list/domain/entities/battle_unit_skill.dart';

class BattleUnitSkillModel {
  final String effectType;
  final int amount;
  final String targetKey;

  const BattleUnitSkillModel({
    required this.effectType,
    required this.amount,
    required this.targetKey,
  });

  factory BattleUnitSkillModel.fromJson(Map<String, dynamic> json) {
    return BattleUnitSkillModel(
      effectType: json['effectType'] as String,
      amount: json['amount'] as int,
      targetKey: json['targetKey'] as String,
    );
  }

  factory BattleUnitSkillModel.fromEntity(BattleUnitSkillEntity entity) {
    return BattleUnitSkillModel(
      effectType: entity.effectType.key,
      amount: entity.amount,
      targetKey: entity.targetKey.key,
    );
  }

  BattleUnitSkillEntity toEntity() {
    return BattleUnitSkillEntity(
      effectType: _parseEffectType(effectType),
      amount: amount < 1 ? 1 : amount,
      targetKey: _parseTargetKey(targetKey),
    );
  }

  Map<String, dynamic> toJson() {
    return {'effectType': effectType, 'amount': amount, 'targetKey': targetKey};
  }

  BattleSkillEffectType _parseEffectType(String rawValue) {
    return switch (rawValue) {
      'heal' => BattleSkillEffectType.heal,
      'damage' => BattleSkillEffectType.damage,
      'buff_attack' => BattleSkillEffectType.buffAttack,
      _ => throw ArgumentError('Unsupported effect type: $rawValue'),
    };
  }

  BattleSkillTargetKey _parseTargetKey(String rawValue) {
    return switch (rawValue) {
      'enemy_in_front' => BattleSkillTargetKey.enemyInFront,
      'ally_in_front' => BattleSkillTargetKey.allyInFront,
      'adjacent_enemies' => BattleSkillTargetKey.adjacentEnemies,
      'adjacent_allies' => BattleSkillTargetKey.adjacentAllies,
      'all_allies_next_to_me' => BattleSkillTargetKey.allAlliesNextToMe,
      'first_enemy_row' => BattleSkillTargetKey.firstEnemyRow,
      _ => throw ArgumentError('Unsupported target key: $rawValue'),
    };
  }
}
