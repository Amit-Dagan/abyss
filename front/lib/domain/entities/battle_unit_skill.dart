enum BattleSkillEffectType { heal, damage, buffAttack }

extension BattleSkillEffectTypeX on BattleSkillEffectType {
  String get key => switch (this) {
    BattleSkillEffectType.heal => 'heal',
    BattleSkillEffectType.damage => 'damage',
    BattleSkillEffectType.buffAttack => 'buff_attack',
  };

  String get label => switch (this) {
    BattleSkillEffectType.heal => 'Heal',
    BattleSkillEffectType.damage => 'Deal Damage',
    BattleSkillEffectType.buffAttack => 'Buff Attack',
  };
}

enum BattleSkillTargetKey {
  enemyInFront,
  allyInFront,
  adjacentEnemies,
  adjacentAllies,
  allAlliesNextToMe,
  firstEnemyRow,
}

extension BattleSkillTargetKeyX on BattleSkillTargetKey {
  String get key => switch (this) {
    BattleSkillTargetKey.enemyInFront => 'enemy_in_front',
    BattleSkillTargetKey.allyInFront => 'ally_in_front',
    BattleSkillTargetKey.adjacentEnemies => 'adjacent_enemies',
    BattleSkillTargetKey.adjacentAllies => 'adjacent_allies',
    BattleSkillTargetKey.allAlliesNextToMe => 'all_allies_next_to_me',
    BattleSkillTargetKey.firstEnemyRow => 'first_enemy_row',
  };

  String get label => switch (this) {
    BattleSkillTargetKey.enemyInFront => 'Enemy In Front',
    BattleSkillTargetKey.allyInFront => 'Ally In Front',
    BattleSkillTargetKey.adjacentEnemies => 'Adjacent Enemies',
    BattleSkillTargetKey.adjacentAllies => 'Adjacent Allies',
    BattleSkillTargetKey.allAlliesNextToMe => 'All Allies Next To Me',
    BattleSkillTargetKey.firstEnemyRow => 'First Enemy Row',
  };
}

class BattleUnitSkillEntity {
  final BattleSkillEffectType effectType;
  final int amount;
  final BattleSkillTargetKey targetKey;

  const BattleUnitSkillEntity({
    required this.effectType,
    required this.amount,
    required this.targetKey,
  });

  BattleUnitSkillEntity copyWith({
    BattleSkillEffectType? effectType,
    int? amount,
    BattleSkillTargetKey? targetKey,
  }) {
    return BattleUnitSkillEntity(
      effectType: effectType ?? this.effectType,
      amount: amount ?? this.amount,
      targetKey: targetKey ?? this.targetKey,
    );
  }
}
