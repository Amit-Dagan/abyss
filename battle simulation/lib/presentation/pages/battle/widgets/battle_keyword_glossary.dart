class BattleKeywordGlossaryEntry {
  final String title;
  final String description;

  const BattleKeywordGlossaryEntry({
    required this.title,
    required this.description,
  });
}

class BattleKeywordGlossary {
  static const Map<String, BattleKeywordGlossaryEntry>
  entries = <String, BattleKeywordGlossaryEntry>{
    'front': BattleKeywordGlossaryEntry(
      title: 'Front',
      description:
          'This unit attacks the single enemy directly in front of it.',
    ),
    'range': BattleKeywordGlossaryEntry(
      title: 'Range',
      description:
          'Range N attacks the first enemy in the same column, as long as that enemy is no more than N tiles away.',
    ),
    'piercer': BattleKeywordGlossaryEntry(
      title: 'Piercer',
      description:
          'This attack travels through the front column and can hit the first two enemies ahead.',
    ),
    'cleave': BattleKeywordGlossaryEntry(
      title: 'Cleave',
      description:
          'This attack hits the front row across three spaces: left, center, and right.',
    ),
    'swinger': BattleKeywordGlossaryEntry(
      title: 'Swinger',
      description: 'This attack hits every adjacent enemy around the unit.',
    ),
    'volley': BattleKeywordGlossaryEntry(
      title: 'Volley',
      description: 'This attack hits the full first enemy row directly ahead.',
    ),
    'longshot': BattleKeywordGlossaryEntry(
      title: 'Longshot',
      description:
          'This attack skips the front square and strikes two rows ahead.',
    ),
    'crusher': BattleKeywordGlossaryEntry(
      title: 'Crusher',
      description:
          'This attack hits the first two enemy spaces in the front column.',
    ),
    'whirlwind': BattleKeywordGlossaryEntry(
      title: 'Whirlwind',
      description:
          'This attack combines adjacent swings with a full front-row hit.',
    ),
    'heal': BattleKeywordGlossaryEntry(
      title: 'Heal',
      description:
          'Healing resolves in cleanup and restores health without affecting the attack already committed that turn.',
    ),
    'poison': BattleKeywordGlossaryEntry(
      title: 'Poison',
      description:
          'Poison deals increasing damage in cleanup: 1, then 2, then 3, and keeps growing while the unit survives.',
    ),
    'fire': BattleKeywordGlossaryEntry(
      title: 'Fire',
      description:
          'Fire deals decreasing damage in cleanup: it starts at its applied value and drops by 1 each turn.',
    ),
    'stun': BattleKeywordGlossaryEntry(
      title: 'Stun',
      description:
          'A stunned unit loses its next turn. Stun takes effect through cleanup and blocks the next action phase.',
    ),
    'taunt': BattleKeywordGlossaryEntry(
      title: 'Taunt',
      description:
          'Taunt is a built-in passive. It visually changes the unit frame and redirects attacks meant for the protected allies.',
    ),
    'rage': BattleKeywordGlossaryEntry(
      title: 'Rage',
      description:
          'Rage gives attack after the unit takes damage, so the bonus only matters on later turns.',
    ),
    'knockback': BattleKeywordGlossaryEntry(
      title: 'Knockback',
      description:
          'Knockback pushes targets away in cleanup before advancing. A knocked unit cannot advance that same turn.',
    ),
    'buff_attack': BattleKeywordGlossaryEntry(
      title: 'Buff Attack',
      description:
          'Buff Attack increases attack in cleanup and only affects future turns.',
    ),
    'debuff_attack': BattleKeywordGlossaryEntry(
      title: 'Debuff Attack',
      description:
          'Debuff Attack reduces attack in cleanup and only affects future turns.',
    ),
  };

  static BattleKeywordGlossaryEntry? lookup(String key) => entries[key];
}
