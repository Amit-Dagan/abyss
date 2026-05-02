import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvvm_remepy/base_page.dart';
import 'package:mvvm_remepy/observer/observer.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_card.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_icon.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_text_formatter.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_arguments.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_model.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_view_model.dart';
import 'package:todo_list/presentation/widgets/editor_session_widgets.dart';
import 'package:todo_list/presentation/widgets/workspace_navigation_widgets.dart';
import 'package:todo_list/domain/services/editor_session_service.dart';
import 'package:todo_list/service_locator.dart';

class UnitEditorScreen extends BasePage<UnitEditorModel, UnitEditorViewModel> {
  const UnitEditorScreen({super.key, required super.viewModel});

  @override
  BasePageState<UnitEditorModel, UnitEditorViewModel, UnitEditorScreen>
  createState() => _UnitEditorScreenState();
}

class _UnitEditorScreenState
    extends
        BasePageState<UnitEditorModel, UnitEditorViewModel, UnitEditorScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final Object? rawArguments = ModalRoute.of(context)?.settings.arguments;
    viewModel.initialize(
      rawArguments is UnitEditorArguments ? rawArguments : null,
    );
  }

  @override
  Color get backgroundColor => AppColors.backgroundColor;

  @override
  PreferredSizeWidget? get appBar => AppBar(
    title: Text(
      model.isExistingUnit ? 'EDIT UNIT' : 'CREATE UNIT',
      style: const TextStyle(
        color: AppColors.whiteColor,
        fontWeight: FontWeight.w800,
      ),
    ),
    backgroundColor: AppColors.primaryColor,
    actions: const <Widget>[
      WorkspaceNavigationAction(
        currentDestination: WorkspaceDestination.simulators,
      ),
      EditorSessionAction(),
    ],
  );

  @override
  Widget get body => ListenableBuilder(
    listenable: sl<EditorSessionService>(),
    builder: (BuildContext context, Widget? child) {
      switch (model.status) {
        case UnitEditorStatus.initial:
        case UnitEditorStatus.loading:
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        case UnitEditorStatus.failure:
          return Center(
            child: Text(
              model.errorMessage ?? 'Failed to load unit editor',
              style: const TextStyle(color: AppColors.primaryColor),
            ),
          );
        case UnitEditorStatus.ready:
        case UnitEditorStatus.saving:
          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const EditorAccessBanner(),
                      AbsorbPointer(
                        absorbing: !viewModel.canEditUnits,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: SizedBox(
                                width: 220,
                                child: BattleUnitCard(
                                  definition: viewModel.previewDefinition,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCleanupHint(),
                            const SizedBox(height: 16),
                            _buildBasicsCard(),
                            const SizedBox(height: 16),
                            _buildIconPickerCard(),
                            const SizedBox(height: 16),
                            _buildAttackPatternCard(),
                            const SizedBox(height: 16),
                            _buildOnHitCard(),
                            const SizedBox(height: 16),
                            _buildTargetedSkillsCard(),
                            const SizedBox(height: 16),
                            _buildPassiveSkillsCard(),
                            const SizedBox(height: 16),
                            _buildGeneratedTextCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
              if (model.status == UnitEditorStatus.saving)
                Container(
                  color: Colors.black.withValues(alpha: 0.08),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                ),
            ],
          );
      }
    },
  );

  Widget _buildCleanupHint() {
    return _buildCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timing rule',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Attack patterns and riders commit first. Direct effects, Fire, Poison, buffs, debuffs, stun, summons, and knockback all resolve in cleanup, so they never change the hit already committed that turn.',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Core stats',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: viewModel.nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: viewModel.attackController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Attack',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: viewModel.healthController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Health',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconPickerCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Icon',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: viewModel.iconPresets
                .map(
                  (BattleUnitIconPreset preset) => InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => viewModel.selectIcon(preset.key),
                    child: Container(
                      width: 92,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: model.iconKey == preset.key
                            ? AppColors.primaryColor
                            : const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          BattleUnitIcon(
                            iconKey: preset.key,
                            size: 36,
                            backgroundColor: model.iconKey == preset.key
                                ? Colors.white.withValues(alpha: 0.18)
                                : AppColors.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            preset.label,
                            style: TextStyle(
                              color: model.iconKey == preset.key
                                  ? Colors.white
                                  : AppColors.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttackPatternCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attack pattern',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BattleAttackPatternKey>(
            initialValue: model.attackPattern,
            decoration: const InputDecoration(
              labelText: 'Pattern',
              border: OutlineInputBorder(),
            ),
            items: viewModel.attackPatterns
                .map(
                  (BattleAttackPatternKey pattern) =>
                      DropdownMenuItem<BattleAttackPatternKey>(
                        value: pattern,
                        child: Text(pattern.label),
                      ),
                )
                .toList(),
            onChanged: viewModel.updateAttackPattern,
          ),
          if (viewModel.showAttackPatternAmount) ...[
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey(
                'attack-pattern-amount-${model.attackPatternAmount}',
              ),
              initialValue: '${model.attackPatternAmount}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Range',
                border: OutlineInputBorder(),
              ),
              onChanged: viewModel.updateAttackPatternAmount,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnHitCard() {
    return _buildSkillSection(
      title: 'On-hit riders',
      emptyLabel: 'No on-hit riders.',
      onAdd: viewModel.addOnHitEffect,
      children: List<Widget>.generate(
        model.onHitEffects.length,
        (int index) => _buildOnHitRow(index, model.onHitEffects[index]),
      ),
    );
  }

  Widget _buildTargetedSkillsCard() {
    return _buildSkillSection(
      title: 'Targeted skills',
      emptyLabel: 'No targeted skills.',
      onAdd: viewModel.addTargetedSkill,
      children: List<Widget>.generate(
        model.targetedSkills.length,
        (int index) =>
            _buildTargetedSkillRow(index, model.targetedSkills[index]),
      ),
    );
  }

  Widget _buildPassiveSkillsCard() {
    return _buildSkillSection(
      title: 'Passive skills',
      emptyLabel: 'No passive skills.',
      onAdd: viewModel.addPassiveSkill,
      children: List<Widget>.generate(
        model.passiveSkills.length,
        (int index) => _buildPassiveSkillRow(index, model.passiveSkills[index]),
      ),
    );
  }

  Widget _buildGeneratedTextCard() {
    final List<String> rules = BattleUnitTextFormatter.buildRulesText(
      viewModel.previewDefinition,
    );

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generated card text',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (rules.isEmpty)
            const Text(
              'Front attack only.',
              style: TextStyle(color: AppColors.primaryColor, fontSize: 13),
            )
          else
            ...rules.map(
              (String line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOnHitRow(int index, BattleOnHitEffectEntity effect) {
    return _buildSkillRowContainer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BattleOnHitEffectType>(
                  initialValue: effect.type,
                  decoration: const InputDecoration(
                    labelText: 'Effect',
                    border: OutlineInputBorder(),
                  ),
                  items: viewModel.onHitEffectTypes
                      .map(
                        (BattleOnHitEffectType type) =>
                            DropdownMenuItem<BattleOnHitEffectType>(
                              value: type,
                              child: Text(type.label),
                            ),
                      )
                      .toList(),
                  onChanged: (BattleOnHitEffectType? value) =>
                      viewModel.updateOnHitType(index, value),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: TextFormField(
                  key: ValueKey('on-hit-amount-$index-${effect.amount}'),
                  initialValue: '${effect.amount}',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (String value) =>
                      viewModel.updateOnHitAmount(index, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRowFooter(
            label: BattleUnitTextFormatter.describeOnHitEffect(effect),
            onMoveUp: index == 0 ? null : () => viewModel.moveOnHit(index, -1),
            onMoveDown: index == model.onHitEffects.length - 1
                ? null
                : () => viewModel.moveOnHit(index, 1),
            onDelete: () => viewModel.removeOnHit(index),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetedSkillRow(int index, BattleTargetedSkillEntity skill) {
    return _buildSkillRowContainer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BattleTargetedSkillType>(
                  initialValue: skill.type,
                  decoration: const InputDecoration(
                    labelText: 'Effect',
                    border: OutlineInputBorder(),
                  ),
                  items: viewModel.targetedSkillTypes
                      .map(
                        (BattleTargetedSkillType type) =>
                            DropdownMenuItem<BattleTargetedSkillType>(
                              value: type,
                              child: Text(type.label),
                            ),
                      )
                      .toList(),
                  onChanged: (BattleTargetedSkillType? value) =>
                      viewModel.updateTargetedSkillType(index, value),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: TextFormField(
                  key: ValueKey('targeted-amount-$index-${skill.amount}'),
                  initialValue: '${skill.amount}',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (String value) =>
                      viewModel.updateTargetedSkillAmount(index, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BattleTargetKey>(
            initialValue: skill.targetKey,
            decoration: const InputDecoration(
              labelText: 'Target',
              border: OutlineInputBorder(),
            ),
            items: viewModel.targetKeys
                .map(
                  (BattleTargetKey key) => DropdownMenuItem<BattleTargetKey>(
                    value: key,
                    child: Text(key.label),
                  ),
                )
                .toList(),
            onChanged: (BattleTargetKey? value) =>
                viewModel.updateTargetedSkillTarget(index, value),
          ),
          const SizedBox(height: 10),
          _buildRowFooter(
            label: BattleUnitTextFormatter.describeTargetedSkill(skill),
            onMoveUp: index == 0
                ? null
                : () => viewModel.moveTargetedSkill(index, -1),
            onMoveDown: index == model.targetedSkills.length - 1
                ? null
                : () => viewModel.moveTargetedSkill(index, 1),
            onDelete: () => viewModel.removeTargetedSkill(index),
          ),
        ],
      ),
    );
  }

  Widget _buildPassiveSkillRow(int index, BattlePassiveSkillEntity skill) {
    return _buildSkillRowContainer(
      child: Column(
        children: [
          DropdownButtonFormField<BattlePassiveSkillType>(
            initialValue: skill.type,
            decoration: const InputDecoration(
              labelText: 'Passive',
              border: OutlineInputBorder(),
            ),
            items: viewModel.passiveSkillTypes
                .map(
                  (BattlePassiveSkillType type) =>
                      DropdownMenuItem<BattlePassiveSkillType>(
                        value: type,
                        child: Text(type.label),
                      ),
                )
                .toList(),
            onChanged: (BattlePassiveSkillType? value) =>
                viewModel.updatePassiveSkillType(index, value),
          ),
          if (viewModel.showPassiveAmount(skill)) ...[
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('passive-amount-$index-${skill.amount}'),
              initialValue: '${skill.amount ?? 1}',
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) =>
                  viewModel.updatePassiveSkillAmount(index, value),
            ),
          ],
          if (viewModel.showPassiveTarget(skill)) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<BattleTargetKey>(
              initialValue: skill.targetKey,
              decoration: const InputDecoration(
                labelText: 'Target',
                border: OutlineInputBorder(),
              ),
              items: viewModel.targetKeys
                  .where(
                    (BattleTargetKey key) =>
                        key != BattleTargetKey.fallenAllies,
                  )
                  .map(
                    (BattleTargetKey key) => DropdownMenuItem<BattleTargetKey>(
                      value: key,
                      child: Text(key.label),
                    ),
                  )
                  .toList(),
              onChanged: (BattleTargetKey? value) =>
                  viewModel.updatePassiveSkillTarget(index, value),
            ),
          ],
          if (skill.type == BattlePassiveSkillType.summoner) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Target: Fallen allies (fixed)',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _buildRowFooter(
            label: BattleUnitTextFormatter.describePassiveSkill(skill),
            onMoveUp: index == 0
                ? null
                : () => viewModel.movePassiveSkill(index, -1),
            onMoveDown: index == model.passiveSkills.length - 1
                ? null
                : () => viewModel.movePassiveSkill(index, 1),
            onDelete: () => viewModel.removePassiveSkill(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillSection({
    required String title,
    required String emptyLabel,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (children.isEmpty)
            Text(
              emptyLabel,
              style: const TextStyle(color: AppColors.primaryColor),
            )
          else
            ...children,
        ],
      ),
    );
  }

  Widget _buildSkillRowContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildRowFooter({
    required String label,
    required VoidCallback? onMoveUp,
    required VoidCallback? onMoveDown,
    required VoidCallback onDelete,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: onMoveUp,
          icon: const Icon(Icons.arrow_upward_rounded),
          color: AppColors.primaryColor,
        ),
        IconButton(
          onPressed: onMoveDown,
          icon: const Icon(Icons.arrow_downward_rounded),
          color: AppColors.primaryColor,
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _buildActions() {
    if (!viewModel.canEditUnits) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            'Close',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (model.isExistingUnit) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _confirmDelete,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveUnit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveUnit() async {
    final bool didSave = await viewModel.saveUnit();
    if (didSave && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete unit?'),
        content: const Text(
          'This removes the unit from the shared Firebase catalog and from battle setup selections.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final bool didDelete = await viewModel.deleteUnit();
    if (didDelete && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void onAlert(AlertModel alertModel) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryColor,
        content: Text(alertModel.body ?? ''),
      ),
    );
  }
}
