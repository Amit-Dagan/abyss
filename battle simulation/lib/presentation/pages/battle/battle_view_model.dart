import 'dart:async';

import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/battle_config.dart';
import 'package:todo_list/domain/entities/battle_enums.dart';
import 'package:todo_list/domain/entities/battle_timeline.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_placement.dart';
import 'package:todo_list/domain/entities/battle_unit_state.dart';
import 'package:todo_list/domain/repo/battle_catalog_repository.dart';
import 'package:todo_list/domain/services/battle_simulator.dart';
import 'package:todo_list/presentation/pages/battle/battle_model.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_text_formatter.dart';
import 'package:todo_list/service_locator.dart';

class BattleViewModel extends ViewModel<BattleModel> {
  final BattleCatalogRepository _catalogRepository =
      sl<BattleCatalogRepository>();
  final BattleSimulator _simulator = BattleSimulator();

  Timer? _autoPlayTimer;
  bool _didInitialize = false;

  BattleViewModel({required super.model});

  BattleConfigEntity get config => model.battleConfig;

  int get rows => config.rows;

  int get columns => config.columns;

  Map<String, BattleUnitDefinitionEntity> get definitionsById => {
    for (final BattleUnitDefinitionEntity definition in model.definitions)
      definition.id: definition,
  };

  BattleSnapshotEntity? get currentSnapshot {
    final BattleTimelineEntity? timeline = model.timeline;
    if (timeline == null || timeline.snapshots.isEmpty) {
      return null;
    }
    return timeline.snapshots[model.currentSnapshotIndex];
  }

  bool isEditableCell(int row) => config.deploymentOwnerForRow(row) != null;

  ArmySide? deploymentOwnerForRow(int row) => config.deploymentOwnerForRow(row);

  BattleUnitPlacementEntity? getPlacementAt(int row, int column) {
    for (final BattleUnitPlacementEntity placement in model.placements) {
      if (placement.row == row && placement.column == column) {
        return placement;
      }
    }
    return null;
  }

  BattleUnitStateEntity? getSnapshotUnitAt(int row, int column) {
    final BattleSnapshotEntity? snapshot = currentSnapshot;
    if (snapshot == null) {
      return null;
    }

    for (final BattleUnitStateEntity unit in snapshot.units) {
      if (unit.row == row && unit.column == column) {
        return unit;
      }
    }
    return null;
  }

  BattleUnitDefinitionEntity? getDefinition(String definitionId) {
    return definitionsById[definitionId];
  }

  List<BattleUnitDefinitionEntity> get availableDefinitions =>
      model.definitions;

  int countUnitsForSide(ArmySide side) {
    if (model.phase == BattlePhase.replay && currentSnapshot != null) {
      return currentSnapshot!.units
          .where((BattleUnitStateEntity unit) => unit.armySide == side)
          .length;
    }

    return model.placements
        .where(
          (BattleUnitPlacementEntity placement) => placement.armySide == side,
        )
        .length;
  }

  Future<void> initialize(dynamic data) async {
    if (_didInitialize) {
      return;
    }
    _didInitialize = true;

    model.battleConfig = data is BattleConfigEntity
        ? data
        : BattleConfigEntity.fallback;
    model.status = BattleScreenStatus.loading;
    notify();

    await _loadDefinitions(isInitialLoad: true);
  }

  Future<void> _loadDefinitions({bool isInitialLoad = false}) async {
    try {
      final List<BattleUnitDefinitionEntity> definitions =
          await _catalogRepository.getUnitDefinitions();
      model.definitions = definitions;
      final Set<String> validIds = definitions
          .map((definition) => definition.id)
          .toSet();
      final List<BattleUnitPlacementEntity> nextPlacements = model.placements
          .where((placement) => validIds.contains(placement.definitionId))
          .toList();
      model.placements = isInitialLoad && nextPlacements.isEmpty
          ? _buildDefaultPlacements(definitions)
          : nextPlacements;
      model.status = BattleScreenStatus.ready;
      if (isInitialLoad) {
        model.phase = BattlePhase.setup;
        model.timeline = null;
        model.currentSnapshotIndex = 0;
      }
      notify();
    } catch (error) {
      model.status = BattleScreenStatus.failure;
      model.errorMessage = error.toString();
      notify();
    }
  }

  @override
  void onViewLoaded(data) {
    super.onViewLoaded(data);
    initialize(data);
  }

  @override
  void onViewResumed() {
    super.onViewResumed();
    _loadDefinitions();
  }

  void setPlacement({
    required int row,
    required int column,
    String? definitionId,
  }) {
    if (!isEditableCell(row)) {
      return;
    }

    final List<BattleUnitPlacementEntity> updatedPlacements =
        List<BattleUnitPlacementEntity>.from(model.placements)..removeWhere(
          (BattleUnitPlacementEntity placement) =>
              placement.row == row && placement.column == column,
        );

    if (definitionId != null) {
      final ArmySide? owner = deploymentOwnerForRow(row);
      if (owner == null) {
        return;
      }
      updatedPlacements.add(
        BattleUnitPlacementEntity(
          armySide: owner,
          definitionId: definitionId,
          row: row,
          column: column,
        ),
      );
    }

    model.placements = updatedPlacements;
    notify();
  }

  void loadDemoFormation() {
    model.placements = _buildDefaultPlacements(model.definitions);
    notify();
  }

  void simulateBattle() {
    _stopAutoPlay();

    model.timeline = _simulator.simulate(
      config: config,
      placements: model.placements,
      definitions: definitionsById,
    );
    model.phase = BattlePhase.replay;
    model.currentSnapshotIndex = 0;
    notify();
  }

  void resetToSetup() {
    _stopAutoPlay();
    model.phase = BattlePhase.setup;
    model.currentSnapshotIndex = 0;
    model.timeline = null;
    notify();
  }

  void setSnapshotIndex(double index) {
    if (model.timeline == null) {
      return;
    }

    model.currentSnapshotIndex = index.round();
    notify();
  }

  void toggleAutoPlay() {
    final BattleTimelineEntity? timeline = model.timeline;
    if (timeline == null || timeline.snapshots.length <= 1) {
      return;
    }

    if (model.isAutoPlaying) {
      _stopAutoPlay();
      notify();
      return;
    }

    if (model.currentSnapshotIndex >= timeline.snapshots.length - 1) {
      model.currentSnapshotIndex = 0;
    }

    model.isAutoPlaying = true;
    notify();

    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 850), (timer) {
      final int lastIndex = timeline.snapshots.length - 1;
      if (model.currentSnapshotIndex >= lastIndex) {
        _stopAutoPlay();
        notify();
        return;
      }

      model.currentSnapshotIndex += 1;
      notify();
    });
  }

  String describeDefinition(BattleUnitDefinitionEntity definition) {
    return BattleUnitTextFormatter.summarize(definition);
  }

  @override
  void dispose() {
    _stopAutoPlay();
    super.dispose();
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    model.isAutoPlaying = false;
  }

  List<BattleUnitPlacementEntity> _buildDefaultPlacements(
    List<BattleUnitDefinitionEntity> definitions,
  ) {
    if (definitions.isEmpty) {
      return const [];
    }

    String resolveId(String preferredId, int fallbackIndex) {
      for (final BattleUnitDefinitionEntity definition in definitions) {
        if (definition.id == preferredId) {
          return definition.id;
        }
      }
      return definitions[fallbackIndex % definitions.length].id;
    }

    final String tankId = resolveId('taunt_tank', 0);
    final String controlId = resolveId('stun_cleaver', 1);
    final String supportId = resolveId('summoner_support', 2);
    final String poisonId = resolveId('poison_swinger', 3);

    if (config.isTournament) {
      return _buildTournamentPlacements(
        tankId: tankId,
        controlId: controlId,
        supportId: supportId,
        poisonId: poisonId,
      );
    }

    return _buildBattlePlacements(
      tankId: tankId,
      controlId: controlId,
      supportId: supportId,
      poisonId: poisonId,
    );
  }

  List<BattleUnitPlacementEntity> _buildBattlePlacements({
    required String tankId,
    required String controlId,
    required String supportId,
    required String poisonId,
  }) {
    final List<int> frontColumns = List<int>.generate(
      columns,
      (int index) => index,
    );
    final List<int> sideColumns = <int>[
      for (int column = 1; column < columns; column += 2) column,
    ];
    final List<int> centerColumns = _centerColumns(columns, 2);

    return <BattleUnitPlacementEntity>[
      ...frontColumns.map(
        (int column) => BattleUnitPlacementEntity(
          armySide: ArmySide.armyA,
          definitionId: tankId,
          row: 2,
          column: column,
        ),
      ),
      ...sideColumns.map(
        (int column) => BattleUnitPlacementEntity(
          armySide: ArmySide.armyA,
          definitionId: controlId,
          row: 1,
          column: column,
        ),
      ),
      ...centerColumns.map(
        (int column) => BattleUnitPlacementEntity(
          armySide: ArmySide.armyA,
          definitionId: supportId,
          row: 0,
          column: column,
        ),
      ),
      ...frontColumns
          .where((int column) => column.isEven)
          .map(
            (int column) => BattleUnitPlacementEntity(
              armySide: ArmySide.armyA,
              definitionId: poisonId,
              row: 1,
              column: column,
            ),
          ),
      ...frontColumns.map(
        (int column) => BattleUnitPlacementEntity(
          armySide: ArmySide.armyB,
          definitionId: tankId,
          row: rows - 3,
          column: column,
        ),
      ),
      ...sideColumns.map(
        (int column) => BattleUnitPlacementEntity(
          armySide: ArmySide.armyB,
          definitionId: controlId,
          row: rows - 2,
          column: column,
        ),
      ),
      ...centerColumns.map(
        (int column) => BattleUnitPlacementEntity(
          armySide: ArmySide.armyB,
          definitionId: supportId,
          row: rows - 1,
          column: column,
        ),
      ),
      ...frontColumns
          .where((int column) => column.isEven)
          .map(
            (int column) => BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: poisonId,
              row: rows - 2,
              column: column,
            ),
          ),
    ];
  }

  List<BattleUnitPlacementEntity> _buildTournamentPlacements({
    required String tankId,
    required String controlId,
    required String supportId,
    required String poisonId,
  }) {
    final List<String> cycle = <String>[tankId, controlId, supportId, poisonId];
    final List<BattleUnitPlacementEntity> placements =
        <BattleUnitPlacementEntity>[];
    final int rowsPerSide = rows ~/ 2;

    for (final ArmySide side in ArmySide.values) {
      final int rowOffset = side == ArmySide.armyA ? 0 : rowsPerSide;
      int index = 0;

      for (int localRow = 0; localRow < rowsPerSide; localRow++) {
        for (int column = 0; column < columns; column++) {
          placements.add(
            BattleUnitPlacementEntity(
              armySide: side,
              definitionId: cycle[index % cycle.length],
              row: rowOffset + localRow,
              column: column,
            ),
          );
          index += 1;
        }
      }
    }

    return placements;
  }

  List<int> _centerColumns(int totalColumns, int count) {
    if (totalColumns <= 0 || count <= 0) {
      return const <int>[];
    }

    final Set<int> centered = <int>{};
    final int middleLeft = (totalColumns - 1) ~/ 2;
    final int middleRight = totalColumns ~/ 2;
    centered.add(middleLeft);
    if (count > 1) {
      centered.add(middleRight);
    }

    return centered.toList()..sort();
  }
}
