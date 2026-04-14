import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/data/model/battle_unit_definition_model.dart';
import 'package:todo_list/data/repo/battle_repo_impl/catalog_file_storage.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/repo/battle_catalog_repository.dart';

class LocalBattleCatalogRepository implements BattleCatalogRepository {
  static const String _relativeFilePath = 'dev_data/unit_definitions.json';
  static const String _webPrefsKey = 'battle_unit_definitions_json_v2';

  final String? filePathOverride;
  final CatalogFileStorage _fileStorage;

  LocalBattleCatalogRepository({
    this.filePathOverride,
    CatalogFileStorage? fileStorage,
  }) : _fileStorage = fileStorage ?? createCatalogFileStorage();

  @override
  Future<List<BattleUnitDefinitionEntity>> getUnitDefinitions() async {
    final List<BattleUnitDefinitionModel> models = await _readModels();
    return models
        .map((BattleUnitDefinitionModel model) => model.toEntity())
        .toList(growable: false);
  }

  @override
  Future<BattleUnitDefinitionEntity?> getUnitDefinition(String unitId) async {
    final List<BattleUnitDefinitionEntity> definitions =
        await getUnitDefinitions();
    for (final BattleUnitDefinitionEntity definition in definitions) {
      if (definition.id == unitId) {
        return definition;
      }
    }
    return null;
  }

  @override
  Future<void> saveUnitDefinition(BattleUnitDefinitionEntity definition) async {
    final List<BattleUnitDefinitionModel> models = await _readModels();
    final int existingIndex = models.indexWhere(
      (model) => model.id == definition.id,
    );
    final BattleUnitDefinitionModel nextModel =
        BattleUnitDefinitionModel.fromEntity(definition);

    if (existingIndex >= 0) {
      models[existingIndex] = nextModel;
    } else {
      models.add(nextModel);
    }

    models.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _writeModels(models);
  }

  @override
  Future<void> deleteUnitDefinition(String unitId) async {
    final List<BattleUnitDefinitionModel> models = await _readModels();
    models.removeWhere((BattleUnitDefinitionModel model) => model.id == unitId);
    await _writeModels(models);
  }

  Future<List<BattleUnitDefinitionModel>> _readModels() async {
    final String rawJson = kIsWeb
        ? await _readWebJson()
        : await _fileStorage.readAsString(await _resolveFilePath());
    final List<dynamic> decoded = json.decode(rawJson) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) =>
              BattleUnitDefinitionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> _writeModels(List<BattleUnitDefinitionModel> models) async {
    final JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    final String payload = encoder.convert(
      models.map((BattleUnitDefinitionModel model) => model.toJson()).toList(),
    );
    if (kIsWeb) {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setString(_webPrefsKey, '$payload\n');
      return;
    }

    final String filePath = await _resolveFilePath();
    await _fileStorage.ensureParentDirectory(filePath);
    await _fileStorage.writeAsString(filePath, '$payload\n');
  }

  Future<String> _resolveFilePath() async {
    final String? override = filePathOverride;
    if (override != null && override.isNotEmpty) {
      await _fileStorage.ensureParentDirectory(override);
      return override;
    }

    final List<String> candidates = <String>[
      _fileStorage.join(_fileStorage.currentDirectoryPath, _relativeFilePath),
      _fileStorage.join(
        _fileStorage.currentDirectoryPath,
        'front/$_relativeFilePath',
      ),
    ];

    for (final String candidate in candidates) {
      if (await _fileStorage.exists(candidate)) {
        return candidate;
      }
    }

    final String fallback = candidates.first;
    await _fileStorage.ensureParentDirectory(fallback);
    if (!await _fileStorage.exists(fallback)) {
      await _fileStorage.writeAsString(fallback, '[]\n');
    }
    return fallback;
  }

  Future<String> _readWebJson() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? persistedJson = preferences.getString(_webPrefsKey);
    if (persistedJson != null && persistedJson.isNotEmpty) {
      return persistedJson;
    }

    final String seedJson = await rootBundle.loadString(_relativeFilePath);
    await preferences.setString(_webPrefsKey, seedJson);
    return seedJson;
  }
}
