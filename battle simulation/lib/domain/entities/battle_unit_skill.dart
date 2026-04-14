enum BattleAttackPatternKey {
  front,
  range,
  piercer,
  cleave,
  swinger,
  volley,
  longshot,
  crusher,
  whirlwind,
}

extension BattleAttackPatternKeyX on BattleAttackPatternKey {
  String get key => switch (this) {
    BattleAttackPatternKey.front => 'front',
    BattleAttackPatternKey.range => 'range',
    BattleAttackPatternKey.piercer => 'piercer',
    BattleAttackPatternKey.cleave => 'cleave',
    BattleAttackPatternKey.swinger => 'swinger',
    BattleAttackPatternKey.volley => 'volley',
    BattleAttackPatternKey.longshot => 'longshot',
    BattleAttackPatternKey.crusher => 'crusher',
    BattleAttackPatternKey.whirlwind => 'whirlwind',
  };

  String get label => switch (this) {
    BattleAttackPatternKey.front => 'Front',
    BattleAttackPatternKey.range => 'Range',
    BattleAttackPatternKey.piercer => 'Piercer',
    BattleAttackPatternKey.cleave => 'Cleave',
    BattleAttackPatternKey.swinger => 'Swinger',
    BattleAttackPatternKey.volley => 'Volley',
    BattleAttackPatternKey.longshot => 'Longshot',
    BattleAttackPatternKey.crusher => 'Crusher',
    BattleAttackPatternKey.whirlwind => 'Whirlwind',
  };
}

enum BattleTargetKey {
  frontEnemy,
  frontAlly,
  adjacentEnemies,
  adjacentAllies,
  allAlliesNextToMe,
  alliesBehindMe,
  enemiesBehindMe,
  sameColumnEnemies,
  firstEnemyRow,
  backRowEnemies,
  fallenAllies,
}

extension BattleTargetKeyX on BattleTargetKey {
  String get key => switch (this) {
    BattleTargetKey.frontEnemy => 'front_enemy',
    BattleTargetKey.frontAlly => 'front_ally',
    BattleTargetKey.adjacentEnemies => 'adjacent_enemies',
    BattleTargetKey.adjacentAllies => 'adjacent_allies',
    BattleTargetKey.allAlliesNextToMe => 'all_allies_next_to_me',
    BattleTargetKey.alliesBehindMe => 'allies_behind_me',
    BattleTargetKey.enemiesBehindMe => 'enemies_behind_me',
    BattleTargetKey.sameColumnEnemies => 'same_column_enemies',
    BattleTargetKey.firstEnemyRow => 'first_enemy_row',
    BattleTargetKey.backRowEnemies => 'back_row_enemies',
    BattleTargetKey.fallenAllies => 'fallen_allies',
  };

  String get label => switch (this) {
    BattleTargetKey.frontEnemy => 'Front Enemy',
    BattleTargetKey.frontAlly => 'Front Ally',
    BattleTargetKey.adjacentEnemies => 'Adjacent Enemies',
    BattleTargetKey.adjacentAllies => 'Adjacent Allies',
    BattleTargetKey.allAlliesNextToMe => 'All Allies Next To Me',
    BattleTargetKey.alliesBehindMe => 'Allies Behind Me',
    BattleTargetKey.enemiesBehindMe => 'Enemies Behind Me',
    BattleTargetKey.sameColumnEnemies => 'Same Column Enemies',
    BattleTargetKey.firstEnemyRow => 'First Enemy Row',
    BattleTargetKey.backRowEnemies => 'Back Row Enemies',
    BattleTargetKey.fallenAllies => 'Fallen Allies',
  };
}

enum BattleTargetedSkillType {
  heal,
  damage,
  buffAttack,
  debuffAttack,
  stun,
  knockback,
  fire,
  poison,
}

extension BattleTargetedSkillTypeX on BattleTargetedSkillType {
  String get key => switch (this) {
    BattleTargetedSkillType.heal => 'heal',
    BattleTargetedSkillType.damage => 'damage',
    BattleTargetedSkillType.buffAttack => 'buff_attack',
    BattleTargetedSkillType.debuffAttack => 'debuff_attack',
    BattleTargetedSkillType.stun => 'stun',
    BattleTargetedSkillType.knockback => 'knockback',
    BattleTargetedSkillType.fire => 'fire',
    BattleTargetedSkillType.poison => 'poison',
  };

  String get label => switch (this) {
    BattleTargetedSkillType.heal => 'Heal',
    BattleTargetedSkillType.damage => 'Deal Damage',
    BattleTargetedSkillType.buffAttack => 'Buff Attack',
    BattleTargetedSkillType.debuffAttack => 'Debuff Attack',
    BattleTargetedSkillType.stun => 'Stun',
    BattleTargetedSkillType.knockback => 'Knockback',
    BattleTargetedSkillType.fire => 'Fire',
    BattleTargetedSkillType.poison => 'Poison',
  };
}

enum BattleOnHitEffectType { poison, fire, stun, knockback, debuffAttack }

extension BattleOnHitEffectTypeX on BattleOnHitEffectType {
  String get key => switch (this) {
    BattleOnHitEffectType.poison => 'poison',
    BattleOnHitEffectType.fire => 'fire',
    BattleOnHitEffectType.stun => 'stun',
    BattleOnHitEffectType.knockback => 'knockback',
    BattleOnHitEffectType.debuffAttack => 'debuff_attack',
  };

  String get label => switch (this) {
    BattleOnHitEffectType.poison => 'Poison',
    BattleOnHitEffectType.fire => 'Fire',
    BattleOnHitEffectType.stun => 'Stun',
    BattleOnHitEffectType.knockback => 'Knockback',
    BattleOnHitEffectType.debuffAttack => 'Debuff Attack',
  };
}

enum BattlePassiveSkillType { taunt, summoner, rage }

extension BattlePassiveSkillTypeX on BattlePassiveSkillType {
  String get key => switch (this) {
    BattlePassiveSkillType.taunt => 'taunt',
    BattlePassiveSkillType.summoner => 'summoner',
    BattlePassiveSkillType.rage => 'rage',
  };

  String get label => switch (this) {
    BattlePassiveSkillType.taunt => 'Taunt',
    BattlePassiveSkillType.summoner => 'Summoner',
    BattlePassiveSkillType.rage => 'Rage',
  };
}

class BattleTargetedSkillEntity {
  final BattleTargetedSkillType type;
  final int amount;
  final BattleTargetKey targetKey;

  const BattleTargetedSkillEntity({
    required this.type,
    required this.amount,
    required this.targetKey,
  });

  BattleTargetedSkillEntity copyWith({
    BattleTargetedSkillType? type,
    int? amount,
    BattleTargetKey? targetKey,
  }) {
    return BattleTargetedSkillEntity(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      targetKey: targetKey ?? this.targetKey,
    );
  }
}

class BattleOnHitEffectEntity {
  final BattleOnHitEffectType type;
  final int amount;

  const BattleOnHitEffectEntity({required this.type, required this.amount});

  BattleOnHitEffectEntity copyWith({BattleOnHitEffectType? type, int? amount}) {
    return BattleOnHitEffectEntity(
      type: type ?? this.type,
      amount: amount ?? this.amount,
    );
  }
}

class BattlePassiveSkillEntity {
  final BattlePassiveSkillType type;
  final int? amount;
  final BattleTargetKey? targetKey;

  const BattlePassiveSkillEntity({
    required this.type,
    this.amount,
    this.targetKey,
  });

  BattlePassiveSkillEntity copyWith({
    BattlePassiveSkillType? type,
    int? amount,
    BattleTargetKey? targetKey,
  }) {
    return BattlePassiveSkillEntity(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      targetKey: targetKey ?? this.targetKey,
    );
  }
}
