import 'package:todo_list/core/app_build_info.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_remepy/base_page.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/domain/entities/battle_config.dart';
import 'package:todo_list/presentation/pages/battle_settings/battle_settings_model.dart';
import 'package:todo_list/presentation/pages/battle_settings/battle_settings_view_model.dart';
import 'package:todo_list/presentation/widgets/editor_session_widgets.dart';
import 'package:todo_list/presentation/widgets/workspace_navigation_widgets.dart';

class BattleSettingsScreen
    extends BasePage<BattleSettingsModel, BattleSettingsViewModel> {
  const BattleSettingsScreen({super.key, required super.viewModel});

  @override
  BasePageState<
    BattleSettingsModel,
    BattleSettingsViewModel,
    BattleSettingsScreen
  >
  createState() => _BattleSettingsScreenState();
}

class _BattleSettingsScreenState
    extends
        BasePageState<
          BattleSettingsModel,
          BattleSettingsViewModel,
          BattleSettingsScreen
        > {
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
    automaticallyImplyLeading: false,
    backgroundColor: AppColors.primaryColor,
    actions: [
      const WorkspaceNavigationAction(
        currentDestination: WorkspaceDestination.simulators,
      ),
      IconButton(
        onPressed: () => Navigator.pushNamed(context, '/units'),
        tooltip: 'Manage Units',
        icon: const Icon(Icons.style_rounded, color: Colors.white),
      ),
      const EditorSessionAction(),
    ],
  );

  @override
  Widget get body => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIntroCard(),
          const SizedBox(height: 16),
          _buildModePicker(),
          const SizedBox(height: 16),
          if (model.selectedMode == BattleMode.battle)
            _buildBattleOptions()
          else
            _buildTournamentOptions(),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: viewModel.startBattle,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Start Battle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Choose the battlefield',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EEE2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  appBuildLabel,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick a battle format first, then choose the board size for this run. Unit placement still happens on the next screen.',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use this build label to confirm the latest deploy is live.',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Format',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: BattleMode.values.map((BattleMode mode) {
              final bool selected = model.selectedMode == mode;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: mode == BattleMode.battle ? 10 : 0,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => viewModel.selectMode(mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryColor
                            : const Color(0xFFF0F2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        mode.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Battle map',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rows stay fixed at 8. Choose the number of columns.',
            style: TextStyle(color: AppColors.primaryColor, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(5, (int index) {
              final int columns = index + 4;
              final bool selected = model.battleColumns == columns;
              return ChoiceChip(
                label: Text('8 x $columns'),
                selected: selected,
                onSelected: (_) => viewModel.selectBattleColumns(columns),
                selectedColor: AppColors.primaryColor,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: const Color(0xFFF0F2FF),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tournament map',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tournament boards are symmetric, with Red on the top half and Blue on the bottom half.',
            style: TextStyle(color: AppColors.primaryColor, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...TournamentPreset.values.map((TournamentPreset preset) {
            final bool selected = model.selectedTournamentPreset == preset;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => viewModel.selectTournamentPreset(preset),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryColor
                        : const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          preset.label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${preset.rows} x ${preset.columns}',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final BattleConfigEntity config = viewModel.selectedConfig;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            config.summaryLabel,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            config.isBattle
                ? 'Deployment uses 3 rows, a 2-row gap, then 3 rows.'
                : 'Deployment uses the top half for Red and bottom half for Blue, with no gap. Both sides compress toward the center and win by elimination.',
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
