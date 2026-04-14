import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';

class BattleRuleSegment {
  final String text;
  final String? glossaryKey;

  const BattleRuleSegment({required this.text, this.glossaryKey});
}

class BattleRuleLine {
  final List<BattleRuleSegment> segments;

  const BattleRuleLine({required this.segments});

  String get plainText =>
      segments.map((BattleRuleSegment segment) => segment.text).join();
}

class BattleUnitTextFormatter {
  static String describeTargetedSkill(BattleTargetedSkillEntity skill) {
    return _targetedSkillLine(skill).plainText;
  }

  static String describeOnHitEffect(BattleOnHitEffectEntity effect) {
    return _onHitLine(effect).plainText;
  }

  static String describePassiveSkill(BattlePassiveSkillEntity skill) {
    return _passiveSkillLine(skill).plainText;
  }

  static String describeAttackPattern(BattleAttackPatternKey pattern) {
    return _attackPatternLine(pattern, null).plainText;
  }

  static List<BattleRuleLine> buildRuleLines(
    BattleUnitDefinitionEntity definition,
  ) {
    return <BattleRuleLine>[
      if (definition.attackPattern != BattleAttackPatternKey.front)
        _attackPatternLine(
          definition.attackPattern,
          definition.attackPatternAmount,
        ),
      ...definition.onHitEffects.map(_onHitLine),
      ...definition.targetedSkills.map(_targetedSkillLine),
      ...definition.passiveSkills.map(_passiveSkillLine),
    ];
  }

  static List<String> buildRulesText(BattleUnitDefinitionEntity definition) {
    return buildRuleLines(
      definition,
    ).map((BattleRuleLine line) => line.plainText).toList(growable: false);
  }

  static String summarize(BattleUnitDefinitionEntity definition) {
    final List<String> lines = buildRulesText(definition);
    if (lines.isEmpty) {
      return 'Front attack only.';
    }
    return lines.join(' ');
  }

  static BattleRuleLine _targetedSkillLine(BattleTargetedSkillEntity skill) {
    final String targetLabel = _targetLabel(skill.targetKey);
    return switch (skill.type) {
      BattleTargetedSkillType.heal => _line(<BattleRuleSegment>[
        _text('Skill: '),
        _keyword('Heal', 'heal'),
        _text(' ${skill.amount} to $targetLabel.'),
      ]),
      BattleTargetedSkillType.damage => _line(<BattleRuleSegment>[
        _text('Skill: Deal ${skill.amount} damage to $targetLabel.'),
      ]),
      BattleTargetedSkillType.buffAttack => _line(<BattleRuleSegment>[
        _text('Skill: Give +${skill.amount} '),
        _keyword('Buff Attack', 'buff_attack'),
        _text(' to $targetLabel.'),
      ]),
      BattleTargetedSkillType.debuffAttack => _line(<BattleRuleSegment>[
        _text('Skill: Give -${skill.amount} '),
        _keyword('Debuff Attack', 'debuff_attack'),
        _text(' to $targetLabel.'),
      ]),
      BattleTargetedSkillType.stun => _line(<BattleRuleSegment>[
        _text('Skill: '),
        _keyword('Stun', 'stun'),
        _text(' $targetLabel for ${skill.amount} turn(s).'),
      ]),
      BattleTargetedSkillType.knockback => _line(<BattleRuleSegment>[
        _text('Skill: '),
        _keyword('Knockback', 'knockback'),
        _text(' $targetLabel up to ${skill.amount} square(s).'),
      ]),
      BattleTargetedSkillType.fire => _line(<BattleRuleSegment>[
        _text('Skill: Apply ${skill.amount} '),
        _keyword('Fire', 'fire'),
        _text(' to $targetLabel.'),
      ]),
      BattleTargetedSkillType.poison => _line(<BattleRuleSegment>[
        _text('Skill: Apply ${skill.amount} '),
        _keyword('Poison', 'poison'),
        _text(' to $targetLabel.'),
      ]),
    };
  }

  static BattleRuleLine _onHitLine(BattleOnHitEffectEntity effect) {
    return switch (effect.type) {
      BattleOnHitEffectType.poison => _line(<BattleRuleSegment>[
        _text('On hit: Apply ${effect.amount} '),
        _keyword('Poison', 'poison'),
        _text('.'),
      ]),
      BattleOnHitEffectType.fire => _line(<BattleRuleSegment>[
        _text('On hit: Apply ${effect.amount} '),
        _keyword('Fire', 'fire'),
        _text('.'),
      ]),
      BattleOnHitEffectType.stun => _line(<BattleRuleSegment>[
        _text('On hit: '),
        _keyword('Stun', 'stun'),
        _text(' the target for ${effect.amount} turn(s).'),
      ]),
      BattleOnHitEffectType.knockback => _line(<BattleRuleSegment>[
        _text('On hit: '),
        _keyword('Knockback', 'knockback'),
        _text(' the target ${effect.amount} square(s).'),
      ]),
      BattleOnHitEffectType.debuffAttack => _line(<BattleRuleSegment>[
        _text('On hit: Give the target -${effect.amount} '),
        _keyword('Debuff Attack', 'debuff_attack'),
        _text('.'),
      ]),
    };
  }

  static BattleRuleLine _passiveSkillLine(BattlePassiveSkillEntity skill) {
    return switch (skill.type) {
      BattlePassiveSkillType.taunt => _line(<BattleRuleSegment>[
        _text('Passive: '),
        _keyword('Taunt', 'taunt'),
        _text(' ${_targetLabel(skill.targetKey!)}.'),
      ]),
      BattlePassiveSkillType.summoner => _line(<BattleRuleSegment>[
        _text('Passive: Summon up to ${skill.amount} fallen ally/allies.'),
      ]),
      BattlePassiveSkillType.rage => _line(<BattleRuleSegment>[
        _text('Passive: Gain +${skill.amount} attack from '),
        _keyword('Rage', 'rage'),
        _text(' after taking damage.'),
      ]),
    };
  }

  static BattleRuleLine _attackPatternLine(
    BattleAttackPatternKey pattern,
    int? amount,
  ) {
    return switch (pattern) {
      BattleAttackPatternKey.front => _line(<BattleRuleSegment>[
        _text('Attack: '),
        _keyword('Front', 'front'),
        _text('.'),
      ]),
      BattleAttackPatternKey.range => _line(<BattleRuleSegment>[
        _text('Attack: '),
        _keyword('Range', 'range'),
        _text(
          ' ${amount ?? 1}, hit the first enemy up to ${amount ?? 1} tile(s) away in the same column.',
        ),
      ]),
      BattleAttackPatternKey.piercer => _line(<BattleRuleSegment>[
        _text('Attack: '),
        _keyword('Piercer', 'piercer'),
        _text(', hit 2 enemies in the front column.'),
      ]),
      BattleAttackPatternKey.cleave => _line(<BattleRuleSegment>[
        _text('Attack: '),
        _keyword('Cleave', 'cleave'),
        _text(', hit 3 spaces in the front row.'),
      ]),
      BattleAttackPatternKey.swinger => _line(<BattleRuleSegment>[
        _text('Attack: '),
        _keyword('Swinger', 'swinger'),
        _text(', hit all adjacent enemies.'),
      ]),
      BattleAttackPatternKey.volley => _line(<BattleRuleSegment>[
        _text('Attack: '),
        _keyword('Volley', 'volley'),
        _text(', hit the full first enemy row.'),
      ]),
      BattleAttackPatternKey.longshot => _line(<BattleRuleSegment>[
        _text('Attack: '),
        _keyword('Longshot', 'longshot'),
        _text(', skip the front square and strike 2 ahead.'),
      ]),
      BattleAttackPatternKey.crusher => _line(<BattleRuleSegment>[
        _text('Attack: '),
        _keyword('Crusher', 'crusher'),
        _text(', hit the first 2 squares in the front column.'),
      ]),
      BattleAttackPatternKey.whirlwind => _line(<BattleRuleSegment>[
        _text('Attack: '),
        _keyword('Whirlwind', 'whirlwind'),
        _text(', hit adjacent enemies and the front row.'),
      ]),
    };
  }

  static BattleRuleLine _line(List<BattleRuleSegment> segments) {
    return BattleRuleLine(segments: segments);
  }

  static BattleRuleSegment _text(String text) => BattleRuleSegment(text: text);

  static BattleRuleSegment _keyword(String text, String key) =>
      BattleRuleSegment(text: text, glossaryKey: key);

  static String _targetLabel(BattleTargetKey key) {
    return switch (key) {
      BattleTargetKey.frontEnemy => 'front enemy',
      BattleTargetKey.frontAlly => 'front ally',
      BattleTargetKey.adjacentEnemies => 'adjacent enemies',
      BattleTargetKey.adjacentAllies => 'adjacent allies',
      BattleTargetKey.allAlliesNextToMe => 'all allies next to me',
      BattleTargetKey.alliesBehindMe => 'allies behind me',
      BattleTargetKey.enemiesBehindMe => 'enemies behind me',
      BattleTargetKey.sameColumnEnemies => 'same-column enemies',
      BattleTargetKey.firstEnemyRow => 'the first enemy row',
      BattleTargetKey.backRowEnemies => 'the enemy back row',
      BattleTargetKey.fallenAllies => 'fallen allies',
    };
  }
}
