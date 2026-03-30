import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mvvm_remepy/observer/observer.dart';
import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';
import 'package:todo_list/domain/repo/battle_catalog_repository.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_icon.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_arguments.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_model.dart';
import 'package:todo_list/service_locator.dart';

class UnitEditorViewModel extends ViewModel<UnitEditorModel> {
  final BattleCatalogRepository _catalogRepository =
      sl<BattleCatalogRepository>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortCodeController = TextEditingController();
  final TextEditingController _attackController = TextEditingController();
  final TextEditingController _healthController = TextEditingController();

  bool _isSyncingControllers = false;
  bool _didInitialize = false;

  UnitEditorViewModel({required super.model}) {
    _nameController.addListener(_onFieldChanged);
    _shortCodeController.addListener(_onFieldChanged);
    _attackController.addListener(_onFieldChanged);
    _healthController.addListener(_onFieldChanged);
  }

  TextEditingController get nameController => _nameController;

  TextEditingController get shortCodeController => _shortCodeController;

  TextEditingController get attackController => _attackController;

  TextEditingController get healthController => _healthController;

  List<BattleUnitIconPreset> get iconPresets => BattleUnitIcon.presets;

  List<BattleSkillEffectType> get effectTypes => BattleSkillEffectType.values;

  List<BattleSkillTargetKey> get targetKeys => BattleSkillTargetKey.values;

  BattleUnitDefinitionEntity get previewDefinition =>
      BattleUnitDefinitionEntity(
        id: model.unitId ?? 'preview_unit',
        name: _normalizedName,
        shortCode: _normalizedShortCode,
        iconKey: model.iconKey,
        attack: _normalizedAttack,
        health: _normalizedHealth,
        skills: model.skills,
      );

  Future<void> initialize(UnitEditorArguments? arguments) async {
    if (_didInitialize) {
      return;
    }
    _didInitialize = true;

    model.status = UnitEditorStatus.loading;
    notify();

    try {
      final String? unitId = arguments?.unitId;
      if (unitId != null) {
        final BattleUnitDefinitionEntity? definition = await _catalogRepository
            .getUnitDefinition(unitId);
        if (definition == null) {
          throw StateError('Unit not found: $unitId');
        }
        _applyDefinition(definition, isExistingUnit: true);
      } else {
        _applyDefinition(
          const BattleUnitDefinitionEntity(
            id: 'new_unit',
            name: '',
            shortCode: '',
            iconKey: 'soldier',
            attack: 1,
            health: 1,
            skills: <BattleUnitSkillEntity>[],
          ),
          isExistingUnit: false,
        );
      }

      model.status = UnitEditorStatus.ready;
      model.errorMessage = null;
      notify();
    } catch (error) {
      model.status = UnitEditorStatus.failure;
      model.errorMessage = error.toString();
      notify();
    }
  }

  void selectIcon(String iconKey) {
    model.iconKey = iconKey;
    notify();
  }

  void addSkill() {
    model.skills = <BattleUnitSkillEntity>[
      ...model.skills,
      const BattleUnitSkillEntity(
        effectType: BattleSkillEffectType.heal,
        amount: 1,
        targetKey: BattleSkillTargetKey.allyInFront,
      ),
    ];
    notify();
  }

  void updateSkillEffectType(int index, BattleSkillEffectType? effectType) {
    if (effectType == null || !_isValidSkillIndex(index)) {
      return;
    }

    final List<BattleUnitSkillEntity> nextSkills =
        List<BattleUnitSkillEntity>.from(model.skills);
    nextSkills[index] = nextSkills[index].copyWith(effectType: effectType);
    model.skills = nextSkills;
    notify();
  }

  void updateSkillTarget(int index, BattleSkillTargetKey? targetKey) {
    if (targetKey == null || !_isValidSkillIndex(index)) {
      return;
    }

    final List<BattleUnitSkillEntity> nextSkills =
        List<BattleUnitSkillEntity>.from(model.skills);
    nextSkills[index] = nextSkills[index].copyWith(targetKey: targetKey);
    model.skills = nextSkills;
    notify();
  }

  void updateSkillAmount(int index, String rawValue) {
    if (!_isValidSkillIndex(index)) {
      return;
    }

    final int parsed = max(1, int.tryParse(rawValue) ?? 1);
    final List<BattleUnitSkillEntity> nextSkills =
        List<BattleUnitSkillEntity>.from(model.skills);
    nextSkills[index] = nextSkills[index].copyWith(amount: parsed);
    model.skills = nextSkills;
    notify();
  }

  void removeSkill(int index) {
    if (!_isValidSkillIndex(index)) {
      return;
    }

    final List<BattleUnitSkillEntity> nextSkills =
        List<BattleUnitSkillEntity>.from(model.skills)..removeAt(index);
    model.skills = nextSkills;
    notify();
  }

  void moveSkill(int index, int delta) {
    final int targetIndex = index + delta;
    if (!_isValidSkillIndex(index) || !_isValidSkillIndex(targetIndex)) {
      return;
    }

    final List<BattleUnitSkillEntity> nextSkills =
        List<BattleUnitSkillEntity>.from(model.skills);
    final BattleUnitSkillEntity skill = nextSkills.removeAt(index);
    nextSkills.insert(targetIndex, skill);
    model.skills = nextSkills;
    notify();
  }

  Future<bool> saveUnit() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      notifyAlert(
        AlertModel(title: 'Missing Name', body: 'Please give the unit a name.'),
      );
      return false;
    }

    final String shortCode = _normalizedShortCode;
    if (shortCode.isEmpty) {
      notifyAlert(
        AlertModel(
          title: 'Missing Short Code',
          body: 'Add a short code so the card stays readable on the board.',
        ),
      );
      return false;
    }

    model.status = UnitEditorStatus.saving;
    notify();

    try {
      final List<BattleUnitDefinitionEntity> existingUnits =
          await _catalogRepository.getUnitDefinitions();
      final String unitId = model.isExistingUnit && model.unitId != null
          ? model.unitId!
          : _buildUniqueId(name, existingUnits.map((unit) => unit.id).toSet());

      final BattleUnitDefinitionEntity definition = BattleUnitDefinitionEntity(
        id: unitId,
        name: name,
        shortCode: shortCode,
        iconKey: model.iconKey,
        attack: _normalizedAttack,
        health: _normalizedHealth,
        skills: model.skills,
      );

      await _catalogRepository.saveUnitDefinition(definition);
      model
        ..unitId = unitId
        ..isExistingUnit = true
        ..status = UnitEditorStatus.ready
        ..errorMessage = null;
      notify();
      return true;
    } catch (error) {
      model.status = UnitEditorStatus.failure;
      model.errorMessage = error.toString();
      notify();
      notifyAlert(
        AlertModel(
          title: 'Save Failed',
          body: 'The unit could not be saved right now.',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteUnit() async {
    final String? unitId = model.unitId;
    if (!model.isExistingUnit || unitId == null) {
      return false;
    }

    model.status = UnitEditorStatus.saving;
    notify();

    try {
      await _catalogRepository.deleteUnitDefinition(unitId);
      model.status = UnitEditorStatus.ready;
      notify();
      return true;
    } catch (error) {
      model.status = UnitEditorStatus.failure;
      model.errorMessage = error.toString();
      notify();
      notifyAlert(
        AlertModel(
          title: 'Delete Failed',
          body: 'The unit could not be deleted right now.',
        ),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    _attackController.dispose();
    _healthController.dispose();
    super.dispose();
  }

  void _applyDefinition(
    BattleUnitDefinitionEntity definition, {
    required bool isExistingUnit,
  }) {
    model
      ..isExistingUnit = isExistingUnit
      ..unitId = isExistingUnit ? definition.id : null
      ..name = definition.name
      ..shortCode = definition.shortCode
      ..iconKey = definition.iconKey
      ..attack = definition.attack
      ..health = definition.health
      ..skills = List<BattleUnitSkillEntity>.from(definition.skills);

    _syncControllersFromModel();
  }

  void _syncControllersFromModel() {
    _isSyncingControllers = true;
    _nameController.text = model.name;
    _shortCodeController.text = model.shortCode;
    _attackController.text = '${model.attack}';
    _healthController.text = '${model.health}';
    _isSyncingControllers = false;
  }

  void _onFieldChanged() {
    if (_isSyncingControllers) {
      return;
    }

    model
      ..name = _nameController.text
      ..shortCode = _shortCodeController.text
      ..attack = max(1, int.tryParse(_attackController.text) ?? 1)
      ..health = max(1, int.tryParse(_healthController.text) ?? 1);
    notify();
  }

  bool _isValidSkillIndex(int index) {
    return index >= 0 && index < model.skills.length;
  }

  String get _normalizedName {
    final String trimmed = _nameController.text.trim();
    return trimmed.isEmpty ? 'Unnamed Unit' : trimmed;
  }

  String get _normalizedShortCode {
    final String raw = _shortCodeController.text.trim().toUpperCase();
    if (raw.isEmpty) {
      return '';
    }
    return raw.substring(0, min(3, raw.length));
  }

  int get _normalizedAttack =>
      max(1, int.tryParse(_attackController.text) ?? 1);

  int get _normalizedHealth =>
      max(1, int.tryParse(_healthController.text) ?? 1);

  String _buildUniqueId(String name, Set<String> usedIds) {
    final String base = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final String seed = base.isEmpty ? 'unit' : base;
    if (!usedIds.contains(seed)) {
      return seed;
    }

    int suffix = 2;
    while (usedIds.contains('${seed}_$suffix')) {
      suffix += 1;
    }
    return '${seed}_$suffix';
  }
}
