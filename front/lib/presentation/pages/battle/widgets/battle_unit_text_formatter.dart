import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';

class BattleUnitTextFormatter {
  static String describeSkill(BattleUnitSkillEntity skill) {
    final String targetLabel = _targetLabel(skill.targetKey);
    return switch (skill.effectType) {
      BattleSkillEffectType.heal =>
        'Cleanup: Heal ${skill.amount} to $targetLabel.',
      BattleSkillEffectType.damage =>
        'Cleanup: Deal ${skill.amount} damage to $targetLabel.',
      BattleSkillEffectType.buffAttack =>
        'Cleanup: Give +${skill.amount} attack to $targetLabel for future turns.',
    };
  }

  static List<String> buildRulesText(BattleUnitDefinitionEntity definition) {
    return <String>[
      'Basic: Deal ${definition.attack} damage to the enemy in front.',
      ...definition.skills.map(describeSkill),
    ];
  }

  static String summarize(BattleUnitDefinitionEntity definition) {
    if (definition.skills.isEmpty) {
      return 'Basic front attack only.';
    }
    return definition.skills.map(describeSkill).join(' ');
  }

  static String _targetLabel(BattleSkillTargetKey key) {
    return switch (key) {
      BattleSkillTargetKey.enemyInFront => 'the enemy in front',
      BattleSkillTargetKey.allyInFront => 'the ally in front',
      BattleSkillTargetKey.adjacentEnemies => 'all adjacent enemies',
      BattleSkillTargetKey.adjacentAllies => 'adjacent allies',
      BattleSkillTargetKey.allAlliesNextToMe => 'all allies next to me',
      BattleSkillTargetKey.firstEnemyRow =>
        'all enemies in the first row ahead',
    };
  }
}
