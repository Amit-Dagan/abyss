import 'package:todo_list/domain/entities/battle_coordinate.dart';
import 'package:todo_list/domain/entities/battle_config.dart';
import 'package:todo_list/domain/entities/battle_enums.dart';
import 'package:todo_list/domain/entities/battle_timeline.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_placement.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';
import 'package:todo_list/domain/entities/battle_unit_state.dart';

class BattleSimulator {
  static const int maxTurns = 200;
  late BattleConfigEntity _config;

  BattleTimelineEntity simulate({
    required BattleConfigEntity config,
    required List<BattleUnitPlacementEntity> placements,
    required Map<String, BattleUnitDefinitionEntity> definitions,
  }) {
    _config = config;
    final List<_RuntimeUnit> units = _createUnits(
      placements: placements,
      definitions: definitions,
    );

    final List<BattleSnapshotEntity> snapshots = <BattleSnapshotEntity>[
      _buildSnapshot(
        turn: 0,
        units: units,
        events: const <String>['Battle deployed'],
      ),
    ];
    final Set<String> seenStates = <String>{_buildStateKey(units)};

    final BattleResultEntity? setupResult = _resolveEliminationResult(units);
    if (setupResult != null) {
      return BattleTimelineEntity(snapshots: snapshots, result: setupResult);
    }

    if (_hasAttackerBreakthrough(units)) {
      return BattleTimelineEntity(
        snapshots: snapshots,
        result: _buildAttackerVictoryResult(
          'Red Team broke through the back rank',
        ),
      );
    }

    for (int turn = 1; turn <= maxTurns; turn++) {
      final String previousStateKey = _buildStateKey(units);
      final List<String> events = <String>[];

      _beginTurn(units, events);
      _commitActions(units, events);
      _applyCleanup(units, events);

      final BattleResultEntity? cleanupResult = _resolveEliminationResult(
        units,
      );
      if (cleanupResult != null) {
        snapshots.add(_buildSnapshot(turn: turn, units: units, events: events));
        return BattleTimelineEntity(
          snapshots: snapshots,
          result: cleanupResult,
        );
      }

      final List<String> moveEvents = _applyMovement(units);
      if (moveEvents.isNotEmpty) {
        events.addAll(moveEvents);
      }

      _clearAdvanceLocks(units);

      if (_hasAttackerBreakthrough(units)) {
        events.add('Red Team broke through the blue back rank');
        snapshots.add(_buildSnapshot(turn: turn, units: units, events: events));
        return BattleTimelineEntity(
          snapshots: snapshots,
          result: _buildAttackerVictoryResult(
            'Red Team reached the blue back rank',
          ),
        );
      }

      if (events.isEmpty) {
        events.add(
          _config.isBattle
              ? 'Blue Team held the line'
              : 'Both armies held their formation',
        );
      }

      final BattleSnapshotEntity snapshot = _buildSnapshot(
        turn: turn,
        units: units,
        events: events,
      );
      snapshots.add(snapshot);

      final String stateKey = _buildStateKey(units);
      if (!seenStates.add(stateKey) || stateKey == previousStateKey) {
        return BattleTimelineEntity(
          snapshots: snapshots,
          result: _buildSafetyResult(units),
        );
      }
    }

    return BattleTimelineEntity(
      snapshots: snapshots,
      result: _config.isBattle
          ? _buildDefenderVictoryResult('Blue Team survived the turn limit')
          : _buildTournamentSafetyResult(
              units,
              'Tournament reached the turn limit',
            ),
    );
  }

  List<_RuntimeUnit> _createUnits({
    required List<BattleUnitPlacementEntity> placements,
    required Map<String, BattleUnitDefinitionEntity> definitions,
  }) {
    return placements
        .asMap()
        .entries
        .map((entry) {
          final BattleUnitPlacementEntity placement = entry.value;
          final BattleUnitDefinitionEntity definition =
              definitions[placement.definitionId]!;

          return _RuntimeUnit(
            instanceId: '${placement.armySide.name}_${entry.key}',
            definition: definition,
            armySide: placement.armySide,
            startingRow: placement.row,
            startingColumn: placement.column,
            row: placement.row,
            column: placement.column,
            currentHealth: definition.health,
            currentAttack: definition.attack,
          );
        })
        .toList(growable: true);
  }

  void _beginTurn(List<_RuntimeUnit> units, List<String> events) {
    for (final _RuntimeUnit unit in units) {
      unit
        ..disabledThisTurn = false
        ..skipAdvanceThisTurn = false
        ..damageTakenThisTurn = 0;

      if (unit.stunTurnsRemaining > 0) {
        unit
          ..disabledThisTurn = true
          ..skipAdvanceThisTurn = true
          ..stunTurnsRemaining -= 1;
        events.add('${unit.label} is stunned and misses the turn');
      }
    }
  }

  void _commitActions(List<_RuntimeUnit> units, List<String> events) {
    final List<_RuntimeUnit> actingUnits = units.toList()..sort(_sortUnits);

    for (final _RuntimeUnit unit in actingUnits) {
      if (unit.disabledThisTurn || unit.currentHealth <= 0) {
        continue;
      }

      _commitAttackPattern(unit: unit, units: units, events: events);
      _commitTargetedSkills(unit: unit, units: units, events: events);
    }
  }

  void _commitAttackPattern({
    required _RuntimeUnit unit,
    required List<_RuntimeUnit> units,
    required List<String> events,
  }) {
    final List<_RuntimeUnit> rawTargets = _resolveAttackTargets(
      sourceUnit: unit,
      units: units,
      pattern: unit.definition.attackPattern,
      patternAmount: unit.definition.attackPatternAmount,
    );

    for (final _RuntimeUnit rawTarget in rawTargets) {
      final _RuntimeUnit target = _resolveTauntRedirect(
        attacker: unit,
        originalTarget: rawTarget,
        units: units,
      );

      _queueDamage(target, unit.currentAttack);
      events.add(
        '${unit.label} struck ${target.label} for ${unit.currentAttack}',
      );

      for (final BattleOnHitEffectEntity effect
          in unit.definition.onHitEffects) {
        _queueOnHitEffect(source: unit, target: target, effect: effect);
        events.add(
          '${unit.label} applied ${effect.type.label} ${effect.amount} to ${target.label}',
        );
      }
    }
  }

  void _commitTargetedSkills({
    required _RuntimeUnit unit,
    required List<_RuntimeUnit> units,
    required List<String> events,
  }) {
    for (final BattleTargetedSkillEntity skill
        in unit.definition.targetedSkills) {
      final List<_RuntimeUnit> targets = _resolveTargetUnits(
        sourceUnit: unit,
        units: units,
        targetKey: skill.targetKey,
      );
      if (targets.isEmpty) {
        continue;
      }

      for (final _RuntimeUnit target in targets) {
        _queueTargetedSkillEffect(source: unit, target: target, skill: skill);
      }

      events.add(
        '${unit.label} queued ${skill.type.label.toLowerCase()} on ${targets.length} target(s)',
      );
    }
  }

  List<_RuntimeUnit> _resolveAttackTargets({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required BattleAttackPatternKey pattern,
    required int? patternAmount,
  }) {
    final ArmySide enemySide = _opponentOf(sourceUnit.armySide);

    final List<_RuntimeUnit> targets = switch (pattern) {
      BattleAttackPatternKey.front => _singleUnitList(
        _findUnitAt(
          units: units,
          row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
          column: sourceUnit.column,
          targetArmySide: enemySide,
        ),
      ),
      BattleAttackPatternKey.range => _singleUnitList(
        _findFirstEnemyInColumnWithinRange(
          sourceUnit: sourceUnit,
          units: units,
          maxDistance: patternAmount ?? 1,
        ),
      ),
      BattleAttackPatternKey.piercer => _findColumnEnemiesAhead(
        sourceUnit: sourceUnit,
        units: units,
        maxTargets: 2,
      ),
      BattleAttackPatternKey.cleave => _findTargetsInExactRow(
        sourceUnit: sourceUnit,
        units: units,
        row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
        targetArmySide: enemySide,
        allowedColumns: <int>[
          sourceUnit.column - 1,
          sourceUnit.column,
          sourceUnit.column + 1,
        ],
      ),
      BattleAttackPatternKey.swinger => _findAdjacentTargets(
        sourceUnit: sourceUnit,
        units: units,
        targetArmySide: enemySide,
      ),
      BattleAttackPatternKey.volley => _findTargetsInExactRow(
        sourceUnit: sourceUnit,
        units: units,
        row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
        targetArmySide: enemySide,
      ),
      BattleAttackPatternKey.longshot => _singleUnitList(
        _findUnitAt(
          units: units,
          row: sourceUnit.row + (sourceUnit.armySide.forwardDirection * 2),
          column: sourceUnit.column,
          targetArmySide: enemySide,
        ),
      ),
      BattleAttackPatternKey.crusher => _findTargetsAtExactOffsets(
        sourceUnit: sourceUnit,
        units: units,
        targetArmySide: enemySide,
        offsets: <BattleCoordinate>[
          BattleCoordinate(
            row: sourceUnit.armySide.forwardDirection,
            column: 0,
          ),
          BattleCoordinate(
            row: sourceUnit.armySide.forwardDirection * 2,
            column: 0,
          ),
        ],
      ),
      BattleAttackPatternKey.whirlwind => _dedupeUnits(<_RuntimeUnit>[
        ..._findAdjacentTargets(
          sourceUnit: sourceUnit,
          units: units,
          targetArmySide: enemySide,
        ),
        ..._findTargetsInExactRow(
          sourceUnit: sourceUnit,
          units: units,
          row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
          targetArmySide: enemySide,
        ),
      ]),
    };

    return _sortUnitList(targets);
  }

  List<_RuntimeUnit> _resolveTargetUnits({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required BattleTargetKey targetKey,
  }) {
    final ArmySide enemySide = _opponentOf(sourceUnit.armySide);
    switch (targetKey) {
      case BattleTargetKey.frontEnemy:
        return _singleUnitList(
          _findUnitAt(
            units: units,
            row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
            column: sourceUnit.column,
            targetArmySide: enemySide,
          ),
        );
      case BattleTargetKey.frontAlly:
        return _singleUnitList(
          _findUnitAt(
            units: units,
            row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
            column: sourceUnit.column,
            targetArmySide: sourceUnit.armySide,
          ),
        );
      case BattleTargetKey.adjacentEnemies:
        return _findAdjacentTargets(
          sourceUnit: sourceUnit,
          units: units,
          targetArmySide: enemySide,
        );
      case BattleTargetKey.adjacentAllies:
      case BattleTargetKey.allAlliesNextToMe:
        return _findAdjacentTargets(
          sourceUnit: sourceUnit,
          units: units,
          targetArmySide: sourceUnit.armySide,
        );
      case BattleTargetKey.alliesBehindMe:
        return _findUnitsBehind(
          sourceUnit: sourceUnit,
          units: units,
          targetArmySide: sourceUnit.armySide,
        );
      case BattleTargetKey.enemiesBehindMe:
        return _findUnitsBehind(
          sourceUnit: sourceUnit,
          units: units,
          targetArmySide: enemySide,
        );
      case BattleTargetKey.sameColumnEnemies:
        return _sortUnitList(
          units
              .where(
                (_RuntimeUnit unit) =>
                    unit.armySide == enemySide &&
                    unit.column == sourceUnit.column,
              )
              .toList(growable: false),
        );
      case BattleTargetKey.firstEnemyRow:
        return _findTargetsInExactRow(
          sourceUnit: sourceUnit,
          units: units,
          row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
          targetArmySide: enemySide,
        );
      case BattleTargetKey.backRowEnemies:
        return _findTargetsInExactRow(
          sourceUnit: sourceUnit,
          units: units,
          row: enemySide == ArmySide.armyA ? 0 : _config.rows - 1,
          targetArmySide: enemySide,
        );
      case BattleTargetKey.fallenAllies:
        return const <_RuntimeUnit>[];
    }
  }

  List<_RuntimeUnit> _findAdjacentTargets({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required ArmySide targetArmySide,
  }) {
    final List<_RuntimeUnit> targets = <_RuntimeUnit>[];
    for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (int columnOffset = -1; columnOffset <= 1; columnOffset++) {
        if (rowOffset == 0 && columnOffset == 0) {
          continue;
        }

        final _RuntimeUnit? target = _findUnitAt(
          units: units,
          row: sourceUnit.row + rowOffset,
          column: sourceUnit.column + columnOffset,
          targetArmySide: targetArmySide,
        );
        if (target != null) {
          targets.add(target);
        }
      }
    }
    return _sortUnitList(targets);
  }

  List<_RuntimeUnit> _findTargetsInExactRow({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required int row,
    required ArmySide targetArmySide,
    List<int>? allowedColumns,
  }) {
    if (!_isInsideBoard(row, 0)) {
      return const <_RuntimeUnit>[];
    }

    final Set<int>? columnFilter = allowedColumns
        ?.where((int column) => column >= 0 && column < _config.columns)
        .toSet();

    return _sortUnitList(
      units
          .where(
            (_RuntimeUnit unit) =>
                unit.armySide == targetArmySide &&
                unit.row == row &&
                (columnFilter == null || columnFilter.contains(unit.column)),
          )
          .toList(growable: false),
    );
  }

  List<_RuntimeUnit> _findTargetsAtExactOffsets({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required ArmySide targetArmySide,
    required List<BattleCoordinate> offsets,
  }) {
    return _sortUnitList(
      _dedupeUnits(
        offsets
            .map(
              (BattleCoordinate offset) => _findUnitAt(
                units: units,
                row: sourceUnit.row + offset.row,
                column: sourceUnit.column + offset.column,
                targetArmySide: targetArmySide,
              ),
            )
            .whereType<_RuntimeUnit>()
            .toList(growable: false),
      ),
    );
  }

  List<_RuntimeUnit> _findColumnEnemiesAhead({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required int maxTargets,
  }) {
    final ArmySide enemySide = _opponentOf(sourceUnit.armySide);
    final List<_RuntimeUnit> targets = units
        .where(
          (_RuntimeUnit unit) =>
              unit.armySide == enemySide &&
              unit.column == sourceUnit.column &&
              (unit.row - sourceUnit.row) *
                      sourceUnit.armySide.forwardDirection >
                  0,
        )
        .toList(growable: false);

    targets.sort(
      (_RuntimeUnit a, _RuntimeUnit b) => ((a.row - sourceUnit.row).abs())
          .compareTo((b.row - sourceUnit.row).abs()),
    );
    return targets.take(maxTargets).toList(growable: false);
  }

  _RuntimeUnit? _findFirstEnemyInColumnWithinRange({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required int maxDistance,
  }) {
    final ArmySide enemySide = _opponentOf(sourceUnit.armySide);
    final List<_RuntimeUnit> targets = units
        .where(
          (_RuntimeUnit unit) =>
              unit.armySide == enemySide &&
              unit.column == sourceUnit.column &&
              (unit.row - sourceUnit.row) *
                      sourceUnit.armySide.forwardDirection >
                  0 &&
              (unit.row - sourceUnit.row).abs() <= maxDistance,
        )
        .toList(growable: false);

    if (targets.isEmpty) {
      return null;
    }

    targets.sort(
      (_RuntimeUnit a, _RuntimeUnit b) => ((a.row - sourceUnit.row).abs())
          .compareTo((b.row - sourceUnit.row).abs()),
    );
    return targets.first;
  }

  List<_RuntimeUnit> _findUnitsBehind({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required ArmySide targetArmySide,
  }) {
    return _sortUnitList(
      units
          .where(
            (_RuntimeUnit unit) =>
                unit.armySide == targetArmySide &&
                unit.instanceId != sourceUnit.instanceId &&
                (unit.row - sourceUnit.row) *
                        sourceUnit.armySide.forwardDirection <
                    0,
          )
          .toList(growable: false),
    );
  }

  _RuntimeUnit _resolveTauntRedirect({
    required _RuntimeUnit attacker,
    required _RuntimeUnit originalTarget,
    required List<_RuntimeUnit> units,
  }) {
    final List<_RuntimeUnit> protectors = units
        .where(
          (_RuntimeUnit candidate) =>
              candidate.armySide == originalTarget.armySide &&
              candidate.instanceId != originalTarget.instanceId &&
              candidate.currentHealth > 0 &&
              _isTauntProtectorFor(
                protector: candidate,
                protectedUnit: originalTarget,
                units: units,
              ),
        )
        .toList(growable: false);

    if (protectors.isEmpty) {
      return originalTarget;
    }

    protectors.sort((_RuntimeUnit a, _RuntimeUnit b) {
      final int distanceCompare = _manhattanDistance(
        a,
        originalTarget,
      ).compareTo(_manhattanDistance(b, originalTarget));
      if (distanceCompare != 0) {
        return distanceCompare;
      }
      return _sortUnits(a, b);
    });

    return protectors.first;
  }

  bool _isTauntProtectorFor({
    required _RuntimeUnit protector,
    required _RuntimeUnit protectedUnit,
    required List<_RuntimeUnit> units,
  }) {
    for (final BattlePassiveSkillEntity skill
        in protector.definition.passiveSkills) {
      if (skill.type != BattlePassiveSkillType.taunt ||
          skill.targetKey == null) {
        continue;
      }

      final List<_RuntimeUnit> protectedUnits = _resolveTargetUnits(
        sourceUnit: protector,
        units: units,
        targetKey: skill.targetKey!,
      );
      if (protectedUnits.any(
        (_RuntimeUnit unit) => unit.instanceId == protectedUnit.instanceId,
      )) {
        return true;
      }
    }

    return false;
  }

  void _queueOnHitEffect({
    required _RuntimeUnit source,
    required _RuntimeUnit target,
    required BattleOnHitEffectEntity effect,
  }) {
    switch (effect.type) {
      case BattleOnHitEffectType.poison:
        target.pendingPoisonStacks.add(effect.amount);
      case BattleOnHitEffectType.fire:
        target.pendingFireStacks.add(effect.amount);
      case BattleOnHitEffectType.stun:
        target.pendingStunTurns += effect.amount;
      case BattleOnHitEffectType.knockback:
        target
          ..pendingKnockbackNet +=
              effect.amount * source.armySide.forwardDirection
          ..skipAdvanceThisTurn = true;
      case BattleOnHitEffectType.debuffAttack:
        target.pendingAttackDelta -= effect.amount;
    }
  }

  void _queueTargetedSkillEffect({
    required _RuntimeUnit source,
    required _RuntimeUnit target,
    required BattleTargetedSkillEntity skill,
  }) {
    switch (skill.type) {
      case BattleTargetedSkillType.heal:
        target.pendingHealthDelta += skill.amount;
      case BattleTargetedSkillType.damage:
        _queueDamage(target, skill.amount);
      case BattleTargetedSkillType.buffAttack:
        target.pendingAttackDelta += skill.amount;
      case BattleTargetedSkillType.debuffAttack:
        target.pendingAttackDelta -= skill.amount;
      case BattleTargetedSkillType.stun:
        target.pendingStunTurns += skill.amount;
      case BattleTargetedSkillType.knockback:
        target
          ..pendingKnockbackNet +=
              skill.amount * source.armySide.forwardDirection
          ..skipAdvanceThisTurn = true;
      case BattleTargetedSkillType.fire:
        target.pendingFireStacks.add(skill.amount);
      case BattleTargetedSkillType.poison:
        target.pendingPoisonStacks.add(skill.amount);
    }
  }

  void _queueDamage(_RuntimeUnit target, int amount) {
    target
      ..pendingHealthDelta -= amount
      ..damageTakenThisTurn += amount;
  }

  void _applyCleanup(List<_RuntimeUnit> units, List<String> events) {
    _applyDirectPendingEffects(units, events);
    _applyDamageOverTime(units, events);

    final List<_RuntimeUnit> fallenInCleanup = _removeDeadUnits(units);
    if (fallenInCleanup.isNotEmpty) {
      events.add(
        '${fallenInCleanup.map((unit) => unit.label).join(', ')} fell in cleanup',
      );
    }

    _applyRage(units, events);
    _resolveSummons(units, fallenInCleanup, events);
    final List<String> knockbackEvents = _applyPendingKnockback(units);
    if (knockbackEvents.isNotEmpty) {
      events.addAll(knockbackEvents);
    }
    _clearPendingEffects(units);
  }

  void _applyDirectPendingEffects(
    List<_RuntimeUnit> units,
    List<String> events,
  ) {
    for (final _RuntimeUnit unit in units) {
      if (unit.pendingHealthDelta != 0) {
        final int before = unit.currentHealth;
        unit.currentHealth = (unit.currentHealth + unit.pendingHealthDelta)
            .clamp(0, unit.definition.health);
        if (before != unit.currentHealth) {
          events.add(
            '${unit.label} health changed by ${unit.currentHealth - before}',
          );
        }
      }

      if (unit.pendingAttackDelta != 0) {
        final int before = unit.currentAttack;
        unit.currentAttack = (unit.currentAttack + unit.pendingAttackDelta)
            .clamp(1, 999);
        if (before != unit.currentAttack) {
          events.add(
            '${unit.label} attack changed by ${unit.currentAttack - before}',
          );
        }
      }

      if (unit.pendingStunTurns > 0) {
        unit.stunTurnsRemaining += unit.pendingStunTurns;
        events.add(
          '${unit.label} is stunned for ${unit.pendingStunTurns} turn(s)',
        );
      }
    }
  }

  void _applyDamageOverTime(List<_RuntimeUnit> units, List<String> events) {
    for (final _RuntimeUnit unit in units) {
      unit.fireStacks.addAll(unit.pendingFireStacks);
      unit.poisonStacks.addAll(unit.pendingPoisonStacks);

      final int fireDamage = unit.fireStacks.fold(
        0,
        (int sum, int stack) => sum + stack,
      );
      final int poisonDamage = unit.poisonStacks.fold(
        0,
        (int sum, int stack) => sum + stack,
      );

      final int totalDamage = fireDamage + poisonDamage;
      if (totalDamage > 0) {
        unit
          ..currentHealth = (unit.currentHealth - totalDamage).clamp(
            0,
            unit.definition.health,
          )
          ..damageTakenThisTurn += totalDamage;
        if (fireDamage > 0) {
          events.add('${unit.label} took $fireDamage Fire damage');
        }
        if (poisonDamage > 0) {
          events.add('${unit.label} took $poisonDamage Poison damage');
        }
      }

      unit.fireStacks = unit.fireStacks
          .map((int stack) => stack - 1)
          .where((int stack) => stack > 0)
          .toList(growable: true);
      unit.poisonStacks = unit.poisonStacks
          .map((int stack) => stack + 1)
          .toList(growable: true);
    }
  }

  void _applyRage(List<_RuntimeUnit> units, List<String> events) {
    for (final _RuntimeUnit unit in units) {
      final int rageGain = unit.rageAmount;
      if (rageGain <= 0 || unit.damageTakenThisTurn <= 0) {
        continue;
      }
      unit.currentAttack = (unit.currentAttack + rageGain).clamp(1, 999);
      events.add('${unit.label} gained +$rageGain attack from Rage');
    }
  }

  void _resolveSummons(
    List<_RuntimeUnit> units,
    List<_RuntimeUnit> fallenInCleanup,
    List<String> events,
  ) {
    if (fallenInCleanup.isEmpty) {
      return;
    }

    final List<_RuntimeUnit> summoners =
        units.where((unit) => unit.remainingSummons > 0).toList(growable: false)
          ..sort(_sortUnits);

    if (summoners.isEmpty) {
      return;
    }

    final Map<ArmySide, List<_RuntimeUnit>> availableBySide =
        <ArmySide, List<_RuntimeUnit>>{
          ArmySide.armyA:
              fallenInCleanup
                  .where((unit) => unit.armySide == ArmySide.armyA)
                  .toList(growable: true)
                ..sort(_sortUnits),
          ArmySide.armyB:
              fallenInCleanup
                  .where((unit) => unit.armySide == ArmySide.armyB)
                  .toList(growable: true)
                ..sort(_sortUnits),
        };

    for (final _RuntimeUnit summoner in summoners) {
      final List<_RuntimeUnit> candidates =
          availableBySide[summoner.armySide] ?? <_RuntimeUnit>[];
      if (candidates.isEmpty) {
        continue;
      }

      int index = 0;
      while (summoner.remainingSummons > 0 && index < candidates.length) {
        final _RuntimeUnit fallen = candidates[index];
        if (_isOccupied(units, fallen.startingRow, fallen.startingColumn)) {
          index += 1;
          continue;
        }

        final _RuntimeUnit revived = fallen.revive();
        units.add(revived);
        summoner.remainingSummons -= 1;
        candidates.removeAt(index);
        events.add('${summoner.label} revived ${revived.label}');
      }
    }
  }

  List<String> _applyPendingKnockback(List<_RuntimeUnit> units) {
    final List<_RuntimeUnit> knockedUnits =
        units
            .where((unit) => unit.pendingKnockbackNet != 0)
            .toList(growable: false)
          ..sort(_sortUnits);
    if (knockedUnits.isEmpty) {
      return const <String>[];
    }

    final int maxSteps = knockedUnits
        .map((unit) => unit.pendingKnockbackNet.abs())
        .fold(
          0,
          (int maxValue, int value) => value > maxValue ? value : maxValue,
        );
    final Map<String, int> movedSteps = <String, int>{};

    for (int step = 0; step < maxSteps; step++) {
      final Set<BattleCoordinate> occupiedCoordinates = units
          .map((unit) => BattleCoordinate(row: unit.row, column: unit.column))
          .toSet();
      final Map<String, BattleCoordinate> proposals =
          <String, BattleCoordinate>{};
      final Map<BattleCoordinate, int> destinationCounts =
          <BattleCoordinate, int>{};

      for (final _RuntimeUnit unit in knockedUnits) {
        final int signedDistance = unit.pendingKnockbackNet;
        if (signedDistance == 0 || signedDistance.abs() <= step) {
          continue;
        }

        final BattleCoordinate nextPosition = BattleCoordinate(
          row: unit.row + signedDistance.sign,
          column: unit.column,
        );

        if (!_isInsideBoard(nextPosition.row, nextPosition.column)) {
          continue;
        }
        if (occupiedCoordinates.contains(nextPosition)) {
          continue;
        }

        proposals[unit.instanceId] = nextPosition;
        destinationCounts[nextPosition] =
            (destinationCounts[nextPosition] ?? 0) + 1;
      }

      for (final _RuntimeUnit unit in knockedUnits) {
        final BattleCoordinate? proposed = proposals[unit.instanceId];
        if (proposed == null || destinationCounts[proposed] != 1) {
          continue;
        }

        unit
          ..row = proposed.row
          ..column = proposed.column;
        movedSteps[unit.instanceId] = (movedSteps[unit.instanceId] ?? 0) + 1;
      }
    }

    return knockedUnits
        .where((unit) => (movedSteps[unit.instanceId] ?? 0) > 0)
        .map(
          (unit) =>
              '${unit.label} was knocked back ${movedSteps[unit.instanceId]} square(s)',
        )
        .toList(growable: false);
  }

  void _clearPendingEffects(List<_RuntimeUnit> units) {
    for (final _RuntimeUnit unit in units) {
      unit.clearPendingEffects();
    }
  }

  void _clearAdvanceLocks(List<_RuntimeUnit> units) {
    for (final _RuntimeUnit unit in units) {
      unit.skipAdvanceThisTurn = false;
    }
  }

  List<_RuntimeUnit> _removeDeadUnits(List<_RuntimeUnit> units) {
    final List<_RuntimeUnit> deadUnits =
        units.where((unit) => unit.currentHealth <= 0).toList(growable: false)
          ..sort(_sortUnits);
    units.removeWhere((unit) => unit.currentHealth <= 0);
    return deadUnits;
  }

  List<String> _applyMovement(List<_RuntimeUnit> units) {
    if (_config.isTournament) {
      return _applyTournamentMovement(units);
    }
    return _applyAttackerMovement(units);
  }

  List<String> _applyAttackerMovement(List<_RuntimeUnit> units) {
    final List<_RuntimeUnit> attackers =
        units
            .where(
              (unit) => unit.armySide.isAttacker && !unit.skipAdvanceThisTurn,
            )
            .toList(growable: false)
          ..sort(_sortUnits);
    if (attackers.isEmpty) {
      return const <String>[];
    }

    final Set<BattleCoordinate> occupiedCoordinates = units
        .map((unit) => BattleCoordinate(row: unit.row, column: unit.column))
        .toSet();
    final Map<String, BattleCoordinate> proposals =
        <String, BattleCoordinate>{};
    final Map<BattleCoordinate, int> destinationCounts =
        <BattleCoordinate, int>{};

    for (final _RuntimeUnit unit in attackers) {
      final BattleCoordinate nextPosition = BattleCoordinate(
        row: unit.row + unit.armySide.forwardDirection,
        column: unit.column,
      );

      if (!_isInsideBoard(nextPosition.row, nextPosition.column)) {
        continue;
      }
      if (occupiedCoordinates.contains(nextPosition)) {
        continue;
      }

      proposals[unit.instanceId] = nextPosition;
      destinationCounts[nextPosition] =
          (destinationCounts[nextPosition] ?? 0) + 1;
    }

    final List<String> moveEvents = <String>[];
    for (final _RuntimeUnit unit in attackers) {
      final BattleCoordinate? proposed = proposals[unit.instanceId];
      if (proposed == null || destinationCounts[proposed] != 1) {
        continue;
      }

      unit
        ..row = proposed.row
        ..column = proposed.column;
      moveEvents.add('${unit.label} advanced to ${proposed.toString()}');
    }

    return moveEvents;
  }

  List<String> _applyTournamentMovement(List<_RuntimeUnit> units) {
    final List<_RuntimeUnit> movers =
        units.where((unit) => !unit.skipAdvanceThisTurn).toList(growable: false)
          ..sort(_sortUnits);
    if (movers.isEmpty) {
      return const <String>[];
    }

    final Set<BattleCoordinate> occupiedCoordinates = units
        .map((unit) => BattleCoordinate(row: unit.row, column: unit.column))
        .toSet();
    final Map<String, BattleCoordinate> proposals =
        <String, BattleCoordinate>{};
    final Map<BattleCoordinate, int> destinationCounts =
        <BattleCoordinate, int>{};

    for (final _RuntimeUnit unit in movers) {
      final BattleCoordinate nextPosition = BattleCoordinate(
        row: unit.row + unit.armySide.forwardDirection,
        column: unit.column,
      );

      if (!_isInsideBoard(nextPosition.row, nextPosition.column)) {
        continue;
      }
      if (!_canAdvanceTowardCenter(unit: unit, nextRow: nextPosition.row)) {
        continue;
      }
      if (occupiedCoordinates.contains(nextPosition)) {
        continue;
      }

      proposals[unit.instanceId] = nextPosition;
      destinationCounts[nextPosition] =
          (destinationCounts[nextPosition] ?? 0) + 1;
    }

    final List<String> moveEvents = <String>[];
    for (final _RuntimeUnit unit in movers) {
      final BattleCoordinate? proposed = proposals[unit.instanceId];
      if (proposed == null || destinationCounts[proposed] != 1) {
        continue;
      }

      unit
        ..row = proposed.row
        ..column = proposed.column;
      moveEvents.add('${unit.label} advanced to ${proposed.toString()}');
    }

    return moveEvents;
  }

  bool _canAdvanceTowardCenter({
    required _RuntimeUnit unit,
    required int nextRow,
  }) {
    if (_config.isBattle) {
      return true;
    }

    final int halfRows = _config.rows ~/ 2;
    if (unit.armySide == ArmySide.armyA) {
      return nextRow < halfRows;
    }
    return nextRow >= halfRows;
  }

  bool _hasAttackerBreakthrough(List<_RuntimeUnit> units) {
    if (_config.isTournament) {
      return false;
    }

    return units.any(
      (_RuntimeUnit unit) =>
          unit.armySide.isAttacker && unit.row == _config.rows - 1,
    );
  }

  BattleResultEntity? _resolveEliminationResult(List<_RuntimeUnit> units) {
    final int attackerCount = _countUnitsForSide(units, ArmySide.armyA);
    final int defenderCount = _countUnitsForSide(units, ArmySide.armyB);

    if (defenderCount == 0) {
      return _buildAttackerVictoryResult('Red Team eliminated every defender');
    }
    if (attackerCount == 0) {
      return _buildDefenderVictoryResult('Blue Team eliminated every attacker');
    }

    return null;
  }

  BattleResultEntity _buildAttackerVictoryResult(String summary) {
    return BattleResultEntity(
      resolution: BattleResolution.attackerVictory,
      winner: ArmySide.armyA,
      summary: summary,
    );
  }

  BattleResultEntity _buildDefenderVictoryResult(String summary) {
    return BattleResultEntity(
      resolution: BattleResolution.defenderVictory,
      winner: ArmySide.armyB,
      summary: summary,
    );
  }

  BattleResultEntity _buildSafetyResult(List<_RuntimeUnit> units) {
    if (_config.isBattle) {
      return _buildDefenderVictoryResult('Blue Team held the line');
    }
    return _buildTournamentSafetyResult(units, 'Tournament stalled');
  }

  BattleResultEntity _buildTournamentSafetyResult(
    List<_RuntimeUnit> units,
    String prefix,
  ) {
    final int redHealth = _totalHealthForSide(units, ArmySide.armyA);
    final int blueHealth = _totalHealthForSide(units, ArmySide.armyB);

    if (redHealth > blueHealth) {
      return _buildAttackerVictoryResult(
        '$prefix, so Red Team won on remaining health',
      );
    }
    if (blueHealth > redHealth) {
      return _buildDefenderVictoryResult(
        '$prefix, so Blue Team won on remaining health',
      );
    }

    final int redUnits = _countUnitsForSide(units, ArmySide.armyA);
    final int blueUnits = _countUnitsForSide(units, ArmySide.armyB);
    if (redUnits >= blueUnits) {
      return _buildAttackerVictoryResult(
        '$prefix, so Red Team won the tiebreak',
      );
    }

    return _buildDefenderVictoryResult(
      '$prefix, so Blue Team won the tiebreak',
    );
  }

  BattleSnapshotEntity _buildSnapshot({
    required int turn,
    required List<_RuntimeUnit> units,
    required List<String> events,
  }) {
    final List<_RuntimeUnit> sortedUnits = units.toList()..sort(_sortUnits);
    return BattleSnapshotEntity(
      turn: turn,
      events: events,
      units: sortedUnits
          .map(
            (_RuntimeUnit unit) => BattleUnitStateEntity.fromRuntime(
              instanceId: unit.instanceId,
              definition: unit.definition,
              armySide: unit.armySide,
              row: unit.row,
              column: unit.column,
              currentHealth: unit.currentHealth,
              currentAttack: unit.currentAttack,
              hasTaunt: unit.hasTaunt,
              isStunned: unit.stunTurnsRemaining > 0,
              isEnraged: unit.currentAttack > unit.definition.attack,
              poisonStacks: unit.totalPoisonStacks,
              fireStacks: unit.totalFireStacks,
            ),
          )
          .toList(growable: false),
    );
  }

  int _countUnitsForSide(List<_RuntimeUnit> units, ArmySide side) {
    return units.where((unit) => unit.armySide == side).length;
  }

  int _totalHealthForSide(List<_RuntimeUnit> units, ArmySide side) {
    return units
        .where((unit) => unit.armySide == side)
        .fold(0, (int sum, _RuntimeUnit unit) => sum + unit.currentHealth);
  }

  _RuntimeUnit? _findUnitAt({
    required List<_RuntimeUnit> units,
    required int row,
    required int column,
    required ArmySide targetArmySide,
  }) {
    if (!_isInsideBoard(row, column)) {
      return null;
    }

    for (final _RuntimeUnit unit in units) {
      if (unit.row == row &&
          unit.column == column &&
          unit.armySide == targetArmySide) {
        return unit;
      }
    }
    return null;
  }

  bool _isOccupied(List<_RuntimeUnit> units, int row, int column) {
    return units.any((unit) => unit.row == row && unit.column == column);
  }

  ArmySide _opponentOf(ArmySide side) =>
      side == ArmySide.armyA ? ArmySide.armyB : ArmySide.armyA;

  List<_RuntimeUnit> _singleUnitList(_RuntimeUnit? unit) =>
      unit == null ? const <_RuntimeUnit>[] : <_RuntimeUnit>[unit];

  List<_RuntimeUnit> _sortUnitList(List<_RuntimeUnit> units) =>
      units.toList(growable: false)..sort(_sortUnits);

  List<_RuntimeUnit> _dedupeUnits(List<_RuntimeUnit> units) {
    final Map<String, _RuntimeUnit> deduped = <String, _RuntimeUnit>{};
    for (final _RuntimeUnit unit in units) {
      deduped[unit.instanceId] = unit;
    }
    return deduped.values.toList(growable: false);
  }

  int _manhattanDistance(_RuntimeUnit a, _RuntimeUnit b) {
    return (a.row - b.row).abs() + (a.column - b.column).abs();
  }

  int _sortUnits(_RuntimeUnit a, _RuntimeUnit b) {
    final int rowCompare = a.row.compareTo(b.row);
    if (rowCompare != 0) {
      return rowCompare;
    }

    final int columnCompare = a.column.compareTo(b.column);
    if (columnCompare != 0) {
      return columnCompare;
    }

    final int armyCompare = a.armySide.index.compareTo(b.armySide.index);
    if (armyCompare != 0) {
      return armyCompare;
    }

    return a.instanceId.compareTo(b.instanceId);
  }

  bool _isInsideBoard(int row, int column) {
    return row >= 0 &&
        row < _config.rows &&
        column >= 0 &&
        column < _config.columns;
  }

  String _buildStateKey(List<_RuntimeUnit> units) {
    final List<_RuntimeUnit> sortedUnits = units.toList()..sort(_sortUnits);
    return sortedUnits
        .map(
          (_RuntimeUnit unit) => [
            unit.instanceId,
            unit.row,
            unit.column,
            unit.currentHealth,
            unit.currentAttack,
            unit.stunTurnsRemaining,
            unit.remainingSummons,
            unit.fireStacks.join(','),
            unit.poisonStacks.join(','),
          ].join(':'),
        )
        .join('|');
  }
}

class _RuntimeUnit {
  final String instanceId;
  final BattleUnitDefinitionEntity definition;
  final ArmySide armySide;
  final int startingRow;
  final int startingColumn;
  int row;
  int column;
  int currentHealth;
  int currentAttack;
  int stunTurnsRemaining = 0;
  int pendingHealthDelta = 0;
  int pendingAttackDelta = 0;
  int pendingStunTurns = 0;
  int pendingKnockbackNet = 0;
  int damageTakenThisTurn = 0;
  bool disabledThisTurn = false;
  bool skipAdvanceThisTurn = false;
  List<int> pendingFireStacks = <int>[];
  List<int> pendingPoisonStacks = <int>[];
  List<int> fireStacks = <int>[];
  List<int> poisonStacks = <int>[];
  late int remainingSummons = definition.passiveSkills
      .where((skill) => skill.type == BattlePassiveSkillType.summoner)
      .fold(
        0,
        (int sum, BattlePassiveSkillEntity skill) => sum + (skill.amount ?? 0),
      );

  _RuntimeUnit({
    required this.instanceId,
    required this.definition,
    required this.armySide,
    required this.startingRow,
    required this.startingColumn,
    required this.row,
    required this.column,
    required this.currentHealth,
    required this.currentAttack,
  });

  String get label =>
      '${definition.name}-${armySide == ArmySide.armyA ? 'R' : 'B'}';

  bool get hasTaunt => definition.passiveSkills.any(
    (BattlePassiveSkillEntity skill) =>
        skill.type == BattlePassiveSkillType.taunt,
  );

  int get rageAmount => definition.passiveSkills
      .where((skill) => skill.type == BattlePassiveSkillType.rage)
      .fold(
        0,
        (int sum, BattlePassiveSkillEntity skill) => sum + (skill.amount ?? 0),
      );

  int get totalFireStacks =>
      fireStacks.fold(0, (int sum, int stack) => sum + stack);

  int get totalPoisonStacks =>
      poisonStacks.fold(0, (int sum, int stack) => sum + stack);

  _RuntimeUnit revive() {
    return _RuntimeUnit(
        instanceId: instanceId,
        definition: definition,
        armySide: armySide,
        startingRow: startingRow,
        startingColumn: startingColumn,
        row: startingRow,
        column: startingColumn,
        currentHealth: definition.health,
        currentAttack: definition.attack,
      )
      ..stunTurnsRemaining = 0
      ..remainingSummons = remainingSummons
      ..fireStacks = <int>[]
      ..poisonStacks = <int>[];
  }

  void clearPendingEffects() {
    pendingHealthDelta = 0;
    pendingAttackDelta = 0;
    pendingStunTurns = 0;
    pendingKnockbackNet = 0;
    pendingFireStacks = <int>[];
    pendingPoisonStacks = <int>[];
  }
}
