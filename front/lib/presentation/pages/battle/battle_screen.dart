import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mvvm_remepy/base_page.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/domain/entities/battle_enums.dart';
import 'package:todo_list/domain/entities/battle_timeline.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_placement.dart';
import 'package:todo_list/domain/entities/battle_unit_state.dart';
import 'package:todo_list/presentation/pages/battle/battle_model.dart';
import 'package:todo_list/presentation/pages/battle/battle_view_model.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_icon.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_text_formatter.dart';

class BattleScreen extends BasePage<BattleModel, BattleViewModel> {
  const BattleScreen({super.key, required super.viewModel});

  @override
  BasePageState<BattleModel, BattleViewModel, BattleScreen> createState() =>
      _BattleScreenState();
}

class _BattleScreenState
    extends BasePageState<BattleModel, BattleViewModel, BattleScreen> {
  @override
  Color get backgroundColor => AppColors.backgroundColor;

  @override
  PreferredSizeWidget? get appBar => AppBar(
    title: Text(
      model.appBarTitle,
      style: const TextStyle(
        color: AppColors.whiteColor,
        fontWeight: FontWeight.w800,
      ),
    ),
    backgroundColor: AppColors.primaryColor,
    actions: [
      IconButton(
        onPressed: () => Navigator.pushNamed(context, '/units'),
        icon: const Icon(Icons.style_rounded, color: Colors.white),
        tooltip: 'Manage Units',
      ),
    ],
  );

  @override
  Widget get body {
    switch (model.status) {
      case BattleScreenStatus.initial:
      case BattleScreenStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        );
      case BattleScreenStatus.failure:
        return Center(
          child: Text(
            model.errorMessage ?? 'Failed to load battle data',
            style: const TextStyle(color: AppColors.primaryColor),
          ),
        );
      case BattleScreenStatus.ready:
        return SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    model.phase == BattlePhase.setup
                        ? _buildHeaderCard()
                        : const SizedBox(),
                    const SizedBox(height: 12),
                    model.phase == BattlePhase.setup
                        ? _buildArmySummary()
                        : const SizedBox(),
                    const SizedBox(height: 12),
                    _buildBoard(constraints),
                    const SizedBox(height: 12),
                    if (model.phase == BattlePhase.setup) ...[
                      _buildUnitLegend(),
                      const SizedBox(height: 12),
                      _buildSetupActions(),
                    ] else ...[
                      _buildReplayPanel(),
                    ],
                  ],
                ),
              );
            },
          ),
        );
    }
  }

  Widget _buildHeaderCard() {
    final bool isSetup = model.phase == BattlePhase.setup;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.boxShadowColor,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSetup ? 'Build the armies' : 'Replay the battle',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSetup
                ? '${viewModel.config.summaryLabel}. Red attacks from the top and Blue defends from the bottom.'
                : model.timeline?.result.summary ?? 'Battle complete',
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArmySummary() {
    final int armyACount = viewModel.countUnitsForSide(ArmySide.armyA);
    final int armyBCount = viewModel.countUnitsForSide(ArmySide.armyB);

    return Row(
      children: [
        Expanded(
          child: _buildArmyChip(
            label: 'Red',
            count: armyACount,
            color: const Color(0xFFE46C7A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildArmyChip(
            label: 'Blue',
            count: armyBCount,
            color: const Color(0xFF4A7BFF),
          ),
        ),
      ],
    );
  }

  Widget _buildArmyChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count units',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(BoxConstraints constraints) {
    final bool isSetup = model.phase == BattlePhase.setup;
    final double viewportHeight = MediaQuery.of(context).size.height;
    final double availableWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width - 24;
    final double availableHeight = viewportHeight * (isSetup ? 0.42 : 0.58);
    final double gap = viewModel.columns <= 2 ? 6 : 4;
    const double outerPadding = 16;
    final double tileSize = math.min(
      (availableWidth - outerPadding - (gap * (viewModel.columns - 1))) /
          viewModel.columns,
      (availableHeight - outerPadding - (gap * (viewModel.rows - 1))) /
          viewModel.rows,
    );
    final double boardWidth =
        (tileSize * viewModel.columns) +
        (gap * (viewModel.columns - 1)) +
        outerPadding;
    final double boardHeight =
        (tileSize * viewModel.rows) +
        (gap * (viewModel.rows - 1)) +
        outerPadding;

    return Center(
      child: SizedBox(
        width: boardWidth,
        height: boardHeight,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2544),
            borderRadius: BorderRadius.circular(20),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.rows * viewModel.columns,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: viewModel.columns,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: 1,
            ),
            itemBuilder: (BuildContext context, int index) {
              final int row = index ~/ viewModel.columns;
              final int column = index % viewModel.columns;
              return _buildCell(context: context, row: row, column: column);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell({
    required BuildContext context,
    required int row,
    required int column,
  }) {
    final bool isSetup = model.phase == BattlePhase.setup;
    final BattleUnitPlacementEntity? placement = viewModel.getPlacementAt(
      row,
      column,
    );
    final BattleUnitStateEntity? snapshotUnit = viewModel.getSnapshotUnitAt(
      row,
      column,
    );

    final BattleUnitDefinitionEntity? definition = isSetup
        ? (placement == null
              ? null
              : viewModel.getDefinition(placement.definitionId))
        : (snapshotUnit == null
              ? null
              : viewModel.getDefinition(snapshotUnit.definitionId));
    final ArmySide? side = isSetup
        ? placement?.armySide
        : snapshotUnit?.armySide;
    final bool editable = isSetup && viewModel.isEditableCell(row);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: editable
            ? () => _showPlacementSheet(
                context: context,
                row: row,
                column: column,
              )
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _tileColor(
              row: row,
              side: side,
              hasUnit: definition != null,
            ),
            border: Border.all(
              color: editable
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool tinyTile = constraints.maxHeight < 34;

              if (definition == null) {
                return Center(
                  child: tinyTile
                      ? Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        )
                      : Text(
                          '$row,$column',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                );
              }

              return Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: BattleUnitIcon(
                    iconKey: definition.iconKey,
                    size: tinyTile ? 18 : 20,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Color _tileColor({
    required int row,
    required ArmySide? side,
    required bool hasUnit,
  }) {
    if (hasUnit && side == ArmySide.armyA) {
      return const Color(0xFFDA556A);
    }
    if (hasUnit && side == ArmySide.armyB) {
      return const Color(0xFF3E66D7);
    }
    final ArmySide? owner = viewModel.deploymentOwnerForRow(row);
    if (owner == ArmySide.armyA) {
      return const Color(0x33533B63);
    }
    if (owner == ArmySide.armyB) {
      return const Color(0x332D557F);
    }
    return const Color(0x22323A67);
  }

  Widget _buildUnitLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unit roster',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...viewModel.availableDefinitions.map(_buildUnitLegendRow),
        ],
      ),
    );
  }

  Widget _buildUnitLegendRow(BattleUnitDefinitionEntity definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: BattleUnitIcon(
              iconKey: definition.iconKey,
              size: 32,
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${definition.name}  ATK ${definition.attack}  HP ${definition.health}',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  BattleUnitTextFormatter.summarize(definition),
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: viewModel.loadDemoFormation,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Load Demo',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.simulateBattle,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Simulate',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplayPanel() {
    final BattleTimelineEntity timeline = model.timeline!;
    final BattleSnapshotEntity snapshot =
        timeline.snapshots[model.currentSnapshotIndex];
    final int lastIndex = timeline.snapshots.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Turn ${snapshot.turn} of ${timeline.snapshots.last.turn}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
              ),
              Slider(
                value: model.currentSnapshotIndex.toDouble(),
                min: 0,
                max: lastIndex.toDouble(),
                divisions: lastIndex == 0 ? 1 : lastIndex,
                activeColor: AppColors.primaryColor,
                onChanged: viewModel.setSnapshotIndex,
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: viewModel.toggleAutoPlay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        model.isAutoPlaying ? 'Pause' : 'Autoplay',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: viewModel.resetToSetup,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Reset / Edit',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Turn events',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 132),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.events
                        .map(
                          (String event) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• $event',
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showPlacementSheet({
    required BuildContext context,
    required int row,
    required int column,
  }) async {
    final String? selectedDefinitionId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tile $row,$column',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.primaryColor,
                  ),
                  title: const Text(
                    'Clear tile',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ''),
                ),
                ...viewModel.availableDefinitions.map(
                  (BattleUnitDefinitionEntity definition) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: BattleUnitIcon(
                      iconKey: definition.iconKey,
                      size: 30,
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    title: Text(
                      definition.name,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      viewModel.describeDefinition(definition),
                      style: const TextStyle(color: AppColors.primaryColor),
                    ),
                    onTap: () => Navigator.pop(context, definition.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedDefinitionId == null) {
      return;
    }

    viewModel.setPlacement(
      row: row,
      column: column,
      definitionId: selectedDefinitionId.isEmpty ? null : selectedDefinitionId,
    );
  }
}
