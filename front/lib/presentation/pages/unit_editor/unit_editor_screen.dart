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
  );

  @override
  Widget get body {
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
                    _buildSkillsCard(),
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
  }

  Widget _buildCleanupHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
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
            'Basic attacks are committed first. Skills resolve later in cleanup, so heals, damage, and buffs never change the attack already made that turn. Buffs only matter on future turns.',
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
                  controller: viewModel.shortCodeController,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(3),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Short code',
                    hintText: 'SOL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          Text(
            'Basic attack: Deal ${viewModel.previewDefinition.attack} damage to the enemy in front.',
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPickerCard() {
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

  Widget _buildSkillsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Skills',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: viewModel.addSkill,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add skill'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (model.skills.isEmpty)
            const Text(
              'No skills yet. This unit will only use its basic attack.',
              style: TextStyle(color: AppColors.primaryColor),
            )
          else
            ...List<Widget>.generate(
              model.skills.length,
              (int index) => _buildSkillRow(index, model.skills[index]),
            ),
          const SizedBox(height: 12),
          const Text(
            'Generated card text',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...BattleUnitTextFormatter.buildRulesText(
            viewModel.previewDefinition,
          ).map(
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

  Widget _buildSkillRow(int index, BattleUnitSkillEntity skill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BattleSkillEffectType>(
                  initialValue: skill.effectType,
                  decoration: const InputDecoration(
                    labelText: 'Effect',
                    border: OutlineInputBorder(),
                  ),
                  items: viewModel.effectTypes
                      .map(
                        (BattleSkillEffectType effectType) =>
                            DropdownMenuItem<BattleSkillEffectType>(
                              value: effectType,
                              child: Text(effectType.label),
                            ),
                      )
                      .toList(),
                  onChanged: (BattleSkillEffectType? value) =>
                      viewModel.updateSkillEffectType(index, value),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: TextFormField(
                  key: ValueKey('skill-amount-$index-${skill.amount}'),
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
                      viewModel.updateSkillAmount(index, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BattleSkillTargetKey>(
            initialValue: skill.targetKey,
            decoration: const InputDecoration(
              labelText: 'Target',
              border: OutlineInputBorder(),
            ),
            items: viewModel.targetKeys
                .map(
                  (BattleSkillTargetKey targetKey) =>
                      DropdownMenuItem<BattleSkillTargetKey>(
                        value: targetKey,
                        child: Text(targetKey.label),
                      ),
                )
                .toList(),
            onChanged: (BattleSkillTargetKey? value) =>
                viewModel.updateSkillTarget(index, value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  BattleUnitTextFormatter.describeSkill(skill),
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: index == 0
                    ? null
                    : () => viewModel.moveSkill(index, -1),
                icon: const Icon(Icons.arrow_upward_rounded),
                color: AppColors.primaryColor,
              ),
              IconButton(
                onPressed: index == model.skills.length - 1
                    ? null
                    : () => viewModel.moveSkill(index, 1),
                icon: const Icon(Icons.arrow_downward_rounded),
                color: AppColors.primaryColor,
              ),
              IconButton(
                onPressed: () => viewModel.removeSkill(index),
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete unit?'),
          content: const Text(
            'This removes the unit from the local JSON catalog and from battle setup selections.',
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
        );
      },
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
