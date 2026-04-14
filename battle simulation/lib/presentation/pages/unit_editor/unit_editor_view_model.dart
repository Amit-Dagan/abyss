import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mvvm_remepy/observer/observer.dart';
import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';
import 'package:todo_list/domain/repo/battle_catalog_repository.dart';
import 'package:todo_list/domain/services/editor_session_service.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_icon.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_arguments.dart';
import 'package:todo_list/presentation/pages/unit_editor/unit_editor_model.dart';
import 'package:todo_list/service_locator.dart';

class UnitEditorViewModel extends ViewModel<UnitEditorModel> {
  final BattleCatalogRepository _catalogRepository =
      sl<BattleCatalogRepository>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _attackController = TextEditingController();
  final TextEditingController _healthController = TextEditingController();

  bool _isSyncingControllers = false;
  bool _didInitialize = false;

  UnitEditorViewModel({required super.model}) {
    _nameController.addListener(_onFieldChanged);
    _attackController.addListener(_onFieldChanged);
    _healthController.addListener(_onFieldChanged);
  }

  TextEditingController get nameController => _nameController;

  TextEditingController get attackController => _attackController;

  TextEditingController get healthController => _healthController;

  List<BattleUnitIconPreset> get iconPresets => BattleUnitIcon.presets;

  List<BattleAttackPatternKey> get attackPatterns =>
      BattleAttackPatternKey.values;

  List<BattleTargetedSkillType> get targetedSkillTypes =>
      BattleTargetedSkillType.values;

  List<BattleOnHitEffectType> get onHitEffectTypes =>
      BattleOnHitEffectType.values;

  List<BattlePassiveSkillType> get passiveSkillTypes =>
      BattlePassiveSkillType.values;

  List<BattleTargetKey> get targetKeys => BattleTargetKey.values;

  bool get canEditUnits => sl<EditorSessionService>().canEditUnits;

  BattleUnitDefinitionEntity get previewDefinition =>
      BattleUnitDefinitionEntity(
        id: model.unitId ?? 'preview_unit',
        name: _normalizedName,
        iconKey: model.iconKey,
        attack: _normalizedAttack,
        health: _normalizedHealth,
        attackPattern: model.attackPattern,
        attackPatternAmount: _effectiveAttackPatternAmount,
        onHitEffects: model.onHitEffects,
        targetedSkills: model.targetedSkills,
        passiveSkills: model.passiveSkills,
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
            iconKey: 'soldier',
            attack: 1,
            health: 1,
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

  void updateAttackPattern(BattleAttackPatternKey? attackPattern) {
    if (attackPattern == null) {
      return;
    }
    model.attackPattern = attackPattern;
    if (attackPattern != BattleAttackPatternKey.range) {
      model.attackPatternAmount = 1;
    }
    notify();
  }

  void updateAttackPatternAmount(String rawValue) {
    model.attackPatternAmount = max(1, int.tryParse(rawValue) ?? 1);
    notify();
  }

  bool get showAttackPatternAmount =>
      model.attackPattern == BattleAttackPatternKey.range;

  void addOnHitEffect() {
    model.onHitEffects = <BattleOnHitEffectEntity>[
      ...model.onHitEffects,
      const BattleOnHitEffectEntity(
        type: BattleOnHitEffectType.poison,
        amount: 1,
      ),
    ];
    notify();
  }

  void addTargetedSkill() {
    model.targetedSkills = <BattleTargetedSkillEntity>[
      ...model.targetedSkills,
      const BattleTargetedSkillEntity(
        type: BattleTargetedSkillType.heal,
        amount: 1,
        targetKey: BattleTargetKey.frontAlly,
      ),
    ];
    notify();
  }

  void addPassiveSkill() {
    model.passiveSkills = <BattlePassiveSkillEntity>[
      ...model.passiveSkills,
      const BattlePassiveSkillEntity(
        type: BattlePassiveSkillType.taunt,
        targetKey: BattleTargetKey.adjacentAllies,
      ),
    ];
    notify();
  }

  void updateOnHitType(int index, BattleOnHitEffectType? type) {
    if (type == null || !_isValidOnHitIndex(index)) {
      return;
    }
    final List<BattleOnHitEffectEntity> next =
        List<BattleOnHitEffectEntity>.from(model.onHitEffects);
    next[index] = next[index].copyWith(type: type);
    model.onHitEffects = next;
    notify();
  }

  void updateOnHitAmount(int index, String rawValue) {
    if (!_isValidOnHitIndex(index)) {
      return;
    }
    final int parsed = max(1, int.tryParse(rawValue) ?? 1);
    final List<BattleOnHitEffectEntity> next =
        List<BattleOnHitEffectEntity>.from(model.onHitEffects);
    next[index] = next[index].copyWith(amount: parsed);
    model.onHitEffects = next;
    notify();
  }

  void moveOnHit(int index, int delta) {
    _moveListItem<BattleOnHitEffectEntity>(
      source: model.onHitEffects,
      assign: (next) => model.onHitEffects = next,
      index: index,
      delta: delta,
    );
  }

  void removeOnHit(int index) {
    if (!_isValidOnHitIndex(index)) {
      return;
    }
    final List<BattleOnHitEffectEntity> next =
        List<BattleOnHitEffectEntity>.from(model.onHitEffects)..removeAt(index);
    model.onHitEffects = next;
    notify();
  }

  void updateTargetedSkillType(int index, BattleTargetedSkillType? type) {
    if (type == null || !_isValidTargetedSkillIndex(index)) {
      return;
    }
    final List<BattleTargetedSkillEntity> next =
        List<BattleTargetedSkillEntity>.from(model.targetedSkills);
    next[index] = next[index].copyWith(type: type);
    model.targetedSkills = next;
    notify();
  }

  void updateTargetedSkillAmount(int index, String rawValue) {
    if (!_isValidTargetedSkillIndex(index)) {
      return;
    }
    final int parsed = max(1, int.tryParse(rawValue) ?? 1);
    final List<BattleTargetedSkillEntity> next =
        List<BattleTargetedSkillEntity>.from(model.targetedSkills);
    next[index] = next[index].copyWith(amount: parsed);
    model.targetedSkills = next;
    notify();
  }

  void updateTargetedSkillTarget(int index, BattleTargetKey? targetKey) {
    if (targetKey == null || !_isValidTargetedSkillIndex(index)) {
      return;
    }
    final List<BattleTargetedSkillEntity> next =
        List<BattleTargetedSkillEntity>.from(model.targetedSkills);
    next[index] = next[index].copyWith(targetKey: targetKey);
    model.targetedSkills = next;
    notify();
  }

  void moveTargetedSkill(int index, int delta) {
    _moveListItem<BattleTargetedSkillEntity>(
      source: model.targetedSkills,
      assign: (next) => model.targetedSkills = next,
      index: index,
      delta: delta,
    );
  }

  void removeTargetedSkill(int index) {
    if (!_isValidTargetedSkillIndex(index)) {
      return;
    }
    final List<BattleTargetedSkillEntity> next =
        List<BattleTargetedSkillEntity>.from(model.targetedSkills)
          ..removeAt(index);
    model.targetedSkills = next;
    notify();
  }

  void updatePassiveSkillType(int index, BattlePassiveSkillType? type) {
    if (type == null || !_isValidPassiveSkillIndex(index)) {
      return;
    }

    BattlePassiveSkillEntity nextSkill = BattlePassiveSkillEntity(type: type);
    switch (type) {
      case BattlePassiveSkillType.taunt:
        nextSkill = const BattlePassiveSkillEntity(
          type: BattlePassiveSkillType.taunt,
          targetKey: BattleTargetKey.adjacentAllies,
        );
      case BattlePassiveSkillType.summoner:
        nextSkill = const BattlePassiveSkillEntity(
          type: BattlePassiveSkillType.summoner,
          amount: 1,
        );
      case BattlePassiveSkillType.rage:
        nextSkill = const BattlePassiveSkillEntity(
          type: BattlePassiveSkillType.rage,
          amount: 1,
        );
    }

    final List<BattlePassiveSkillEntity> next =
        List<BattlePassiveSkillEntity>.from(model.passiveSkills);
    next[index] = nextSkill;
    model.passiveSkills = next;
    notify();
  }

  void updatePassiveSkillAmount(int index, String rawValue) {
    if (!_isValidPassiveSkillIndex(index)) {
      return;
    }
    final int parsed = max(1, int.tryParse(rawValue) ?? 1);
    final List<BattlePassiveSkillEntity> next =
        List<BattlePassiveSkillEntity>.from(model.passiveSkills);
    next[index] = next[index].copyWith(amount: parsed);
    model.passiveSkills = next;
    notify();
  }

  void updatePassiveSkillTarget(int index, BattleTargetKey? targetKey) {
    if (targetKey == null || !_isValidPassiveSkillIndex(index)) {
      return;
    }
    final List<BattlePassiveSkillEntity> next =
        List<BattlePassiveSkillEntity>.from(model.passiveSkills);
    next[index] = next[index].copyWith(targetKey: targetKey);
    model.passiveSkills = next;
    notify();
  }

  void movePassiveSkill(int index, int delta) {
    _moveListItem<BattlePassiveSkillEntity>(
      source: model.passiveSkills,
      assign: (next) => model.passiveSkills = next,
      index: index,
      delta: delta,
    );
  }

  void removePassiveSkill(int index) {
    if (!_isValidPassiveSkillIndex(index)) {
      return;
    }
    final List<BattlePassiveSkillEntity> next =
        List<BattlePassiveSkillEntity>.from(model.passiveSkills)
          ..removeAt(index);
    model.passiveSkills = next;
    notify();
  }

  bool showPassiveAmount(BattlePassiveSkillEntity skill) =>
      skill.type == BattlePassiveSkillType.summoner ||
      skill.type == BattlePassiveSkillType.rage;

  bool showPassiveTarget(BattlePassiveSkillEntity skill) =>
      skill.type == BattlePassiveSkillType.taunt;

  Future<bool> saveUnit() async {
    if (!canEditUnits) {
      notifyAlert(
        AlertModel(
          title: 'Admins Only',
          body:
              'Only users tagged as admin in Firestore can edit the shared unit catalog.',
        ),
      );
      return false;
    }

    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      notifyAlert(
        AlertModel(title: 'Missing Name', body: 'Please give the unit a name.'),
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
        iconKey: model.iconKey,
        attack: _normalizedAttack,
        health: _normalizedHealth,
        attackPattern: model.attackPattern,
        attackPatternAmount: _effectiveAttackPatternAmount,
        onHitEffects: model.onHitEffects,
        targetedSkills: model.targetedSkills,
        passiveSkills: model.passiveSkills,
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
    if (!canEditUnits) {
      notifyAlert(
        AlertModel(
          title: 'Admins Only',
          body:
              'Only users tagged as admin in Firestore can delete from the shared unit catalog.',
        ),
      );
      return false;
    }

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
      ..iconKey = definition.iconKey
      ..attack = definition.attack
      ..health = definition.health
      ..attackPattern = definition.attackPattern
      ..attackPatternAmount = definition.attackPatternAmount ?? 1
      ..onHitEffects = List<BattleOnHitEffectEntity>.from(
        definition.onHitEffects,
      )
      ..targetedSkills = List<BattleTargetedSkillEntity>.from(
        definition.targetedSkills,
      )
      ..passiveSkills = List<BattlePassiveSkillEntity>.from(
        definition.passiveSkills,
      );

    _syncControllersFromModel();
  }

  void _syncControllersFromModel() {
    _isSyncingControllers = true;
    _nameController.text = model.name;
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
      ..attack = max(1, int.tryParse(_attackController.text) ?? 1)
      ..health = max(1, int.tryParse(_healthController.text) ?? 1);
    notify();
  }

  bool _isValidOnHitIndex(int index) =>
      index >= 0 && index < model.onHitEffects.length;

  bool _isValidTargetedSkillIndex(int index) =>
      index >= 0 && index < model.targetedSkills.length;

  bool _isValidPassiveSkillIndex(int index) =>
      index >= 0 && index < model.passiveSkills.length;

  String get _normalizedName {
    final String trimmed = _nameController.text.trim();
    return trimmed.isEmpty ? 'Unnamed Unit' : trimmed;
  }

  int get _normalizedAttack =>
      max(1, int.tryParse(_attackController.text) ?? 1);

  int get _normalizedHealth =>
      max(1, int.tryParse(_healthController.text) ?? 1);

  int? get _effectiveAttackPatternAmount =>
      model.attackPattern == BattleAttackPatternKey.range
      ? max(1, model.attackPatternAmount)
      : null;

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

  void _moveListItem<T>({
    required List<T> source,
    required void Function(List<T>) assign,
    required int index,
    required int delta,
  }) {
    final int targetIndex = index + delta;
    if (index < 0 ||
        index >= source.length ||
        targetIndex < 0 ||
        targetIndex >= source.length) {
      return;
    }

    final List<T> next = List<T>.from(source);
    final T item = next.removeAt(index);
    next.insert(targetIndex, item);
    assign(next);
    notify();
  }
}
