enum ArmySide { armyA, armyB }

extension ArmySideX on ArmySide {
  int get forwardDirection => this == ArmySide.armyA ? 1 : -1;

  bool get isAttacker => this == ArmySide.armyA;

  bool get isDefender => !isAttacker;

  String get label => isAttacker ? 'Red Team' : 'Blue Team';

  String get roleLabel => isAttacker ? 'Attackers' : 'Defenders';
}

enum BattleActionType { damage, heal }

enum BattleTargetType { enemy, friendly }
