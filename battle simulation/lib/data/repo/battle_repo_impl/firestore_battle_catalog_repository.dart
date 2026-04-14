import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:todo_list/data/model/battle_unit_definition_model.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/repo/battle_catalog_repository.dart';

typedef BattleCatalogSeedLoader =
    Future<List<BattleUnitDefinitionEntity>> Function();

class FirestoreBattleCatalogRepository implements BattleCatalogRepository {
  static const String _seedAssetPath = 'dev_data/unit_definitions.json';
  static const Duration _readTimeout = Duration(seconds: 2);

  final FirebaseFirestore _firestore;
  final String? Function() _currentEditorEmail;
  final BattleCatalogSeedLoader _seedLoader;
  final Future<QuerySnapshot<Map<String, dynamic>>> Function(
    CollectionReference<Map<String, dynamic>> collection,
  )
  _loadCollection;
  final Future<DocumentSnapshot<Map<String, dynamic>>> Function(
    DocumentReference<Map<String, dynamic>> document,
  )
  _loadDocument;

  FirestoreBattleCatalogRepository({
    FirebaseFirestore? firestore,
    String? Function()? currentEditorEmail,
    BattleCatalogSeedLoader? seedLoader,
    Future<QuerySnapshot<Map<String, dynamic>>> Function(
      CollectionReference<Map<String, dynamic>> collection,
    )?
    loadCollection,
    Future<DocumentSnapshot<Map<String, dynamic>>> Function(
      DocumentReference<Map<String, dynamic>> document,
    )?
    loadDocument,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _currentEditorEmail =
           currentEditorEmail ??
           (() => FirebaseAuth.instance.currentUser?.email),
       _seedLoader = seedLoader ?? _defaultSeedLoader,
       _loadCollection =
           loadCollection ??
           ((CollectionReference<Map<String, dynamic>> collection) =>
               collection.get()),
       _loadDocument =
           loadDocument ??
           ((DocumentReference<Map<String, dynamic>> document) =>
               document.get());

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('unitDefinitions');

  @override
  Future<void> deleteUnitDefinition(String unitId) async {
    await _collection.doc(unitId).delete();
  }

  @override
  Future<BattleUnitDefinitionEntity?> getUnitDefinition(String unitId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _loadDocument(_collection.doc(unitId)).timeout(_readTimeout);
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }

      return BattleUnitDefinitionModel.fromJson(data).toEntity();
    } on Exception {
      final List<BattleUnitDefinitionEntity> fallbackUnits =
          await _seedLoader();
      for (final BattleUnitDefinitionEntity definition in fallbackUnits) {
        if (definition.id == unitId) {
          return definition;
        }
      }
      return null;
    }
  }

  @override
  Future<List<BattleUnitDefinitionEntity>> getUnitDefinitions() async {
    late final List<BattleUnitDefinitionEntity> units;
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _loadCollection(_collection).timeout(_readTimeout);
      units = snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                BattleUnitDefinitionModel.fromJson(doc.data()).toEntity(),
          )
          .toList(growable: false);
    } on Exception {
      units = await _seedLoader();
    }
    units.sort(
      (BattleUnitDefinitionEntity a, BattleUnitDefinitionEntity b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return units;
  }

  @override
  Future<void> saveUnitDefinition(BattleUnitDefinitionEntity definition) async {
    final Map<String, dynamic> data = BattleUnitDefinitionModel.fromEntity(
      definition,
    ).toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['updatedByEmail'] = _currentEditorEmail();
    await _collection.doc(definition.id).set(data);
  }

  Future<bool> seedIfEmpty() async {
    final QuerySnapshot<Map<String, dynamic>> existing = await _collection
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return false;
    }

    final List<BattleUnitDefinitionEntity> seedDefinitions =
        await _seedLoader();
    if (seedDefinitions.isEmpty) {
      return false;
    }

    final WriteBatch batch = _firestore.batch();
    for (final BattleUnitDefinitionEntity definition in seedDefinitions) {
      final Map<String, dynamic> data = BattleUnitDefinitionModel.fromEntity(
        definition,
      ).toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['updatedByEmail'] = _currentEditorEmail();
      batch.set(_collection.doc(definition.id), data);
    }
    await batch.commit();
    return true;
  }

  static Future<List<BattleUnitDefinitionEntity>> _defaultSeedLoader() async {
    final String rawJson = await rootBundle.loadString(_seedAssetPath);
    final List<dynamic> decoded = json.decode(rawJson) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) => BattleUnitDefinitionModel.fromJson(
            item as Map<String, dynamic>,
          ).toEntity(),
        )
        .toList(growable: false);
  }
}
