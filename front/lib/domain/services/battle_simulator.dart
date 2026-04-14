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
      final List<String> events = <String>[];
      bool hasMeaningfulChange = false;

      _commitBasicAttacks(units, events);
      _commitCleanupSkills(units, events);

      final _CleanupQueue cleanupQueue = _buildCleanupQueue(units);
      if (cleanupQueue.hasAnyEffect) {
        hasMeaningfulChange = true;
      }
      _applyPendingStatEffects(units);

      final List<_RuntimeUnit> fallenInCleanup = _removeDeadUnits(units);
      if (fallenInCleanup.isNotEmpty) {
        events.add(
          '${fallenInCleanup.map((unit) => unit.label).join(', ')} fell in cleanup',
        );
        hasMeaningfulChange = true;
      }

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

      final List<String> knockbackEvents = _applyPendingKnockback(units);
      if (knockbackEvents.isNotEmpty) {
        events.addAll(knockbackEvents);
        hasMeaningfulChange = true;
      }

      _clearPendingEffects(units);

      final List<String> moveEvents = _applyMovement(units);
      if (moveEvents.isNotEmpty) {
        events.addAll(moveEvents);
        hasMeaningfulChange = true;
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
      if (!seenStates.add(stateKey) || !hasMeaningfulChange) {
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
            row: placement.row,
            column: placement.column,
            currentHealth: definition.health,
            currentAttack: definition.attack,
          );
        })
        .toList(growable: true);
  }

  void _commitBasicAttacks(List<_RuntimeUnit> units, List<String> events) {
    final List<_RuntimeUnit> actingUnits = units.toList()..sort(_sortUnits);

    for (final _RuntimeUnit unit in actingUnits) {
      final _RuntimeUnit? target = _findUnitAt(
        units: units,
        row: unit.row + unit.armySide.forwardDirection,
        column: unit.column,
        targetArmySide: unit.armySide == ArmySide.armyA
            ? ArmySide.armyB
            : ArmySide.armyA,
      );
      if (target == null) {
        continue;
      }

      target.pendingHealthDelta -= unit.currentAttack;
      events.add(
        '${unit.label} struck ${target.label} for ${unit.currentAttack}',
      );
    }
  }

  void _commitCleanupSkills(List<_RuntimeUnit> units, List<String> events) {
    final List<_RuntimeUnit> actingUnits = units.toList()..sort(_sortUnits);

    for (final _RuntimeUnit unit in actingUnits) {
      for (final BattleUnitSkillEntity skill in unit.definition.skills) {
        final List<_RuntimeUnit> targets = _findTargets(
          sourceUnit: unit,
          units: units,
          targetKey: skill.targetKey,
        );
        if (targets.isEmpty) {
          continue;
        }

        switch (skill.effectType) {
          case BattleSkillEffectType.heal:
            for (final _RuntimeUnit target in targets) {
              target.pendingHealthDelta += skill.amount;
            }
            events.add(
              '${unit.label} healed ${targets.length} target(s) for ${skill.amount}',
            );
          case BattleSkillEffectType.damage:
            for (final _RuntimeUnit target in targets) {
              target.pendingHealthDelta -= skill.amount;
            }
            events.add(
              '${unit.label} dealt cleanup damage to ${targets.length} target(s)',
            );
          case BattleSkillEffectType.buffAttack:
            for (final _RuntimeUnit target in targets) {
              target.pendingAttackDelta += skill.amount;
            }
            events.add(
              '${unit.label} buffed ${targets.length} target(s) by ${skill.amount} attack',
            );
          case BattleSkillEffectType.knockback:
            for (final _RuntimeUnit target in targets) {
              target.pendingKnockbackDistance += skill.amount;
              target.skipAdvanceThisTurn = true;
            }
            events.add(
              '${unit.label} queued knockback for ${targets.length} target(s)',
            );
        }
      }
    }
  }

  List<_RuntimeUnit> _findTargets({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required BattleSkillTargetKey targetKey,
  }) {
    switch (targetKey) {
      case BattleSkillTargetKey.enemyInFront:
        final _RuntimeUnit? target = _findUnitAt(
          units: units,
          row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
          column: sourceUnit.column,
          targetArmySide: sourceUnit.armySide == ArmySide.armyA
              ? ArmySide.armyB
              : ArmySide.armyA,
        );
        return target == null ? const <_RuntimeUnit>[] : <_RuntimeUnit>[target];
      case BattleSkillTargetKey.allyInFront:
        final _RuntimeUnit? target = _findUnitAt(
          units: units,
          row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
          column: sourceUnit.column,
          targetArmySide: sourceUnit.armySide,
        );
        return target == null ? const <_RuntimeUnit>[] : <_RuntimeUnit>[target];
      case BattleSkillTargetKey.adjacentEnemies:
        return _findAdjacentTargets(
          sourceUnit: sourceUnit,
          units: units,
          targetArmySide: sourceUnit.armySide == ArmySide.armyA
              ? ArmySide.armyB
              : ArmySide.armyA,
        );
      case BattleSkillTargetKey.adjacentAllies:
      case BattleSkillTargetKey.allAlliesNextToMe:
        return _findAdjacentTargets(
          sourceUnit: sourceUnit,
          units: units,
          targetArmySide: sourceUnit.armySide,
        );
      case BattleSkillTargetKey.firstEnemyRow:
        return _findRowTargets(
          sourceUnit: sourceUnit,
          units: units,
          row: sourceUnit.row + sourceUnit.armySide.forwardDirection,
          targetArmySide: sourceUnit.armySide == ArmySide.armyA
              ? ArmySide.armyB
              : ArmySide.armyA,
        );
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
    return targets;
  }

  List<_RuntimeUnit> _findRowTargets({
    required _RuntimeUnit sourceUnit,
    required List<_RuntimeUnit> units,
    required int row,
    required ArmySide targetArmySide,
  }) {
    if (!_isInsideBoard(row, 0)) {
      return const <_RuntimeUnit>[];
    }

    return units
        .where(
          (_RuntimeUnit unit) =>
              unit.row == row && unit.armySide == targetArmySide,
        )
        .toList()
      ..sort(_sortUnits);
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

  _CleanupQueue _buildCleanupQueue(List<_RuntimeUnit> units) {
    final Map<String, int> healthDeltas = <String, int>{};
    final Map<String, int> attackBuffs = <String, int>{};
    final Map<String, int> knockbacks = <String, int>{};

    for (final _RuntimeUnit unit in units) {
      if (unit.pendingHealthDelta != 0) {
        healthDeltas[unit.instanceId] = unit.pendingHealthDelta;
      }
      if (unit.pendingAttackDelta != 0) {
        attackBuffs[unit.instanceId] = unit.pendingAttackDelta;
      }
      if (unit.pendingKnockbackDistance != 0) {
        knockbacks[unit.instanceId] = unit.pendingKnockbackDistance;
      }
    }

    return _CleanupQueue(
      healthDeltas: healthDeltas,
      attackBuffs: attackBuffs,
      knockbacks: knockbacks,
    );
  }

  void _applyPendingStatEffects(List<_RuntimeUnit> units) {
    for (final _RuntimeUnit unit in units) {
      if (unit.pendingHealthDelta != 0) {
        unit.currentHealth = (unit.currentHealth + unit.pendingHealthDelta)
            .clamp(0, unit.definition.health);
      }

      if (unit.pendingAttackDelta != 0) {
        unit.currentAttack = (unit.currentAttack + unit.pendingAttackDelta)
            .clamp(1, 999);
      }
    }
  }

  List<String> _applyPendingKnockback(List<_RuntimeUnit> units) {
    final List<_RuntimeUnit> knockedUnits =
        units.where((unit) => unit.pendingKnockbackDistance > 0).toList()
          ..sort(_sortUnits);
    if (knockedUnits.isEmpty) {
      return const <String>[];
    }

    final int maxSteps = knockedUnits
        .map((unit) => unit.pendingKnockbackDistance)
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
        if (unit.pendingKnockbackDistance <= step) {
          continue;
        }

        final BattleCoordinate nextPosition = BattleCoordinate(
          row: unit.row - unit.armySide.forwardDirection,
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
        units.where((unit) => unit.currentHealth <= 0).toList()
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
            .toList()
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
        units.where((unit) => !unit.skipAdvanceThisTurn).toList()
          ..sort(_sortUnits);
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
          ].join(':'),
        )
        .join('|');
  }
}

class _CleanupQueue {
  final Map<String, int> healthDeltas;
  final Map<String, int> attackBuffs;
  final Map<String, int> knockbacks;

  const _CleanupQueue({
    required this.healthDeltas,
    required this.attackBuffs,
    required this.knockbacks,
  });

  bool get hasAnyEffect =>
      healthDeltas.isNotEmpty ||
      attackBuffs.isNotEmpty ||
      knockbacks.isNotEmpty;
}

class _RuntimeUnit {
  final String instanceId;
  final BattleUnitDefinitionEntity definition;
  final ArmySide armySide;
  int row;
  int column;
  int currentHealth;
  int currentAttack;
  int pendingHealthDelta = 0;
  int pendingAttackDelta = 0;
  int pendingKnockbackDistance = 0;
  bool skipAdvanceThisTurn = false;

  _RuntimeUnit({
    required this.instanceId,
    required this.definition,
    required this.armySide,
    required this.row,
    required this.column,
    required this.currentHealth,
    required this.currentAttack,
  });

  String get label =>
      '${definition.shortCode}-${armySide.isAttacker ? 'R' : 'B'}';

  void clearPendingEffects() {
    pendingHealthDelta = 0;
    pendingAttackDelta = 0;
    pendingKnockbackDistance = 0;
  }
}
