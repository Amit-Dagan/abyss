import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/data/repo/battle_repo_impl/firestore_battle_catalog_repository.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';

void main() {
  group('FirestoreBattleCatalogRepository', () {
    test('roundtrips a unit definition through Firestore', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      final FirestoreBattleCatalogRepository repository =
          FirestoreBattleCatalogRepository(
            firestore: firestore,
            currentEditorEmail: () => 'editor@example.com',
            seedLoader: () async => const <BattleUnitDefinitionEntity>[],
          );

      final BattleUnitDefinitionEntity definition = _definition(
        id: 'guardian',
        name: 'Guardian',
        iconKey: 'soldier',
        attack: 2,
        health: 8,
        attackPattern: BattleAttackPatternKey.range,
        attackPatternAmount: 4,
        onHitEffects: const <BattleOnHitEffectEntity>[
          BattleOnHitEffectEntity(type: BattleOnHitEffectType.fire, amount: 3),
        ],
        targetedSkills: const <BattleTargetedSkillEntity>[
          BattleTargetedSkillEntity(
            type: BattleTargetedSkillType.heal,
            amount: 1,
            targetKey: BattleTargetKey.adjacentAllies,
          ),
        ],
        passiveSkills: const <BattlePassiveSkillEntity>[
          BattlePassiveSkillEntity(
            type: BattlePassiveSkillType.rage,
            amount: 2,
          ),
        ],
      );

      await repository.saveUnitDefinition(definition);

      final List<BattleUnitDefinitionEntity> units = await repository
          .getUnitDefinitions();
      final Map<String, dynamic>? savedData =
          (await firestore.collection('unitDefinitions').doc('guardian').get())
              .data();

      expect(units, hasLength(1));
      expect(units.single.attackPattern, BattleAttackPatternKey.range);
      expect(units.single.attackPatternAmount, 4);
      expect(units.single.onHitEffects.single.type, BattleOnHitEffectType.fire);
      expect(
        units.single.targetedSkills.single.targetKey,
        BattleTargetKey.adjacentAllies,
      );
      expect(units.single.passiveSkills.single.amount, 2);
      expect(savedData?['updatedByEmail'], 'editor@example.com');
    });

    test('seedIfEmpty publishes starter units only once', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      int seedLoaderCalls = 0;

      final FirestoreBattleCatalogRepository repository =
          FirestoreBattleCatalogRepository(
            firestore: firestore,
            currentEditorEmail: () => 'editor@example.com',
            seedLoader: () async {
              seedLoaderCalls += 1;
              return <BattleUnitDefinitionEntity>[
                _definition(
                  id: 'starter',
                  name: 'Starter',
                  iconKey: 'banner',
                  attack: 1,
                  health: 3,
                ),
              ];
            },
          );

      final bool firstSeed = await repository.seedIfEmpty();
      final bool secondSeed = await repository.seedIfEmpty();
      final List<BattleUnitDefinitionEntity> units = await repository
          .getUnitDefinitions();

      expect(firstSeed, isTrue);
      expect(secondSeed, isFalse);
      expect(seedLoaderCalls, 1);
      expect(units.map((BattleUnitDefinitionEntity unit) => unit.id), [
        'starter',
      ]);
    });

    test('falls back to seed units when Firestore reads stall', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

      final FirestoreBattleCatalogRepository repository =
          FirestoreBattleCatalogRepository(
            firestore: firestore,
            currentEditorEmail: () => 'editor@example.com',
            seedLoader: () async => <BattleUnitDefinitionEntity>[
              _definition(
                id: 'fallback_unit',
                name: 'Fallback Unit',
                iconKey: 'banner',
                attack: 2,
                health: 5,
              ),
            ],
            loadCollection:
                (CollectionReference<Map<String, dynamic>> collection) =>
                    Completer<QuerySnapshot<Map<String, dynamic>>>().future,
          );

      final List<BattleUnitDefinitionEntity> units = await repository
          .getUnitDefinitions();

      expect(units, hasLength(1));
      expect(units.single.id, 'fallback_unit');
    });
  });
}

BattleUnitDefinitionEntity _definition({
  required String id,
  required String name,
  required String iconKey,
  required int attack,
  required int health,
  BattleAttackPatternKey attackPattern = BattleAttackPatternKey.front,
  int? attackPatternAmount,
  List<BattleOnHitEffectEntity> onHitEffects =
      const <BattleOnHitEffectEntity>[],
  List<BattleTargetedSkillEntity> targetedSkills =
      const <BattleTargetedSkillEntity>[],
  List<BattlePassiveSkillEntity> passiveSkills =
      const <BattlePassiveSkillEntity>[],
}) {
  return BattleUnitDefinitionEntity(
    id: id,
    name: name,
    iconKey: iconKey,
    attack: attack,
    health: health,
    attackPattern: attackPattern,
    attackPatternAmount: attackPatternAmount,
    onHitEffects: onHitEffects,
    targetedSkills: targetedSkills,
    passiveSkills: passiveSkills,
  );
}
