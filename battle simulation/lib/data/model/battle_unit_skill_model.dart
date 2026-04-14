import 'package:todo_list/domain/entities/battle_unit_skill.dart';

class BattleTargetedSkillModel {
  final String effectType;
  final int amount;
  final String targetKey;

  const BattleTargetedSkillModel({
    required this.effectType,
    required this.amount,
    required this.targetKey,
  });

  factory BattleTargetedSkillModel.fromJson(Map<String, dynamic> json) {
    return BattleTargetedSkillModel(
      effectType: json['effectType'] as String,
      amount: json['amount'] as int,
      targetKey: json['targetKey'] as String,
    );
  }

  factory BattleTargetedSkillModel.fromEntity(
    BattleTargetedSkillEntity entity,
  ) {
    return BattleTargetedSkillModel(
      effectType: entity.type.key,
      amount: entity.amount,
      targetKey: entity.targetKey.key,
    );
  }

  BattleTargetedSkillEntity toEntity() {
    return BattleTargetedSkillEntity(
      type: _parseTargetedSkillType(effectType),
      amount: amount < 1 ? 1 : amount,
      targetKey: _parseTargetKey(targetKey),
    );
  }

  Map<String, dynamic> toJson() {
    return {'effectType': effectType, 'amount': amount, 'targetKey': targetKey};
  }
}

class BattleOnHitEffectModel {
  final String effectType;
  final int amount;

  const BattleOnHitEffectModel({
    required this.effectType,
    required this.amount,
  });

  factory BattleOnHitEffectModel.fromJson(Map<String, dynamic> json) {
    return BattleOnHitEffectModel(
      effectType: json['effectType'] as String,
      amount: json['amount'] as int,
    );
  }

  factory BattleOnHitEffectModel.fromEntity(BattleOnHitEffectEntity entity) {
    return BattleOnHitEffectModel(
      effectType: entity.type.key,
      amount: entity.amount,
    );
  }

  BattleOnHitEffectEntity toEntity() {
    return BattleOnHitEffectEntity(
      type: _parseOnHitEffectType(effectType),
      amount: amount < 1 ? 1 : amount,
    );
  }

  Map<String, dynamic> toJson() {
    return {'effectType': effectType, 'amount': amount};
  }
}

class BattlePassiveSkillModel {
  final String effectType;
  final int? amount;
  final String? targetKey;

  const BattlePassiveSkillModel({
    required this.effectType,
    this.amount,
    this.targetKey,
  });

  factory BattlePassiveSkillModel.fromJson(Map<String, dynamic> json) {
    return BattlePassiveSkillModel(
      effectType: json['effectType'] as String,
      amount: json['amount'] as int?,
      targetKey: json['targetKey'] as String?,
    );
  }

  factory BattlePassiveSkillModel.fromEntity(BattlePassiveSkillEntity entity) {
    return BattlePassiveSkillModel(
      effectType: entity.type.key,
      amount: entity.amount,
      targetKey: entity.targetKey?.key,
    );
  }

  BattlePassiveSkillEntity toEntity() {
    return BattlePassiveSkillEntity(
      type: _parsePassiveSkillType(effectType),
      amount: amount == null ? null : (amount! < 1 ? 1 : amount),
      targetKey: targetKey == null ? null : _parseTargetKey(targetKey!),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'effectType': effectType,
      if (amount != null) 'amount': amount,
      if (targetKey != null) 'targetKey': targetKey,
    };
  }
}

BattleAttackPatternKey parseAttackPatternKey(String rawValue) {
  return switch (rawValue) {
    'front' => BattleAttackPatternKey.front,
    'range' => BattleAttackPatternKey.range,
    'piercer' => BattleAttackPatternKey.piercer,
    'cleave' => BattleAttackPatternKey.cleave,
    'swinger' => BattleAttackPatternKey.swinger,
    'volley' => BattleAttackPatternKey.volley,
    'longshot' => BattleAttackPatternKey.longshot,
    'crusher' => BattleAttackPatternKey.crusher,
    'whirlwind' => BattleAttackPatternKey.whirlwind,
    _ => throw ArgumentError('Unsupported attack pattern: $rawValue'),
  };
}

BattleTargetedSkillType _parseTargetedSkillType(String rawValue) {
  return switch (rawValue) {
    'heal' => BattleTargetedSkillType.heal,
    'damage' => BattleTargetedSkillType.damage,
    'buff_attack' => BattleTargetedSkillType.buffAttack,
    'debuff_attack' => BattleTargetedSkillType.debuffAttack,
    'stun' => BattleTargetedSkillType.stun,
    'knockback' => BattleTargetedSkillType.knockback,
    'fire' => BattleTargetedSkillType.fire,
    'poison' => BattleTargetedSkillType.poison,
    _ => throw ArgumentError('Unsupported targeted skill type: $rawValue'),
  };
}

BattleOnHitEffectType _parseOnHitEffectType(String rawValue) {
  return switch (rawValue) {
    'poison' => BattleOnHitEffectType.poison,
    'fire' => BattleOnHitEffectType.fire,
    'stun' => BattleOnHitEffectType.stun,
    'knockback' => BattleOnHitEffectType.knockback,
    'debuff_attack' => BattleOnHitEffectType.debuffAttack,
    _ => throw ArgumentError('Unsupported on-hit effect type: $rawValue'),
  };
}

BattlePassiveSkillType _parsePassiveSkillType(String rawValue) {
  return switch (rawValue) {
    'taunt' => BattlePassiveSkillType.taunt,
    'summoner' => BattlePassiveSkillType.summoner,
    'rage' => BattlePassiveSkillType.rage,
    _ => throw ArgumentError('Unsupported passive skill type: $rawValue'),
  };
}

BattleTargetKey _parseTargetKey(String rawValue) {
  return switch (rawValue) {
    'front_enemy' => BattleTargetKey.frontEnemy,
    'front_ally' => BattleTargetKey.frontAlly,
    'adjacent_enemies' => BattleTargetKey.adjacentEnemies,
    'adjacent_allies' => BattleTargetKey.adjacentAllies,
    'all_allies_next_to_me' => BattleTargetKey.allAlliesNextToMe,
    'allies_behind_me' => BattleTargetKey.alliesBehindMe,
    'enemies_behind_me' => BattleTargetKey.enemiesBehindMe,
    'same_column_enemies' => BattleTargetKey.sameColumnEnemies,
    'first_enemy_row' => BattleTargetKey.firstEnemyRow,
    'back_row_enemies' => BattleTargetKey.backRowEnemies,
    'fallen_allies' => BattleTargetKey.fallenAllies,
    _ => throw ArgumentError('Unsupported target key: $rawValue'),
  };
}
