import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/data/model/battle_unit_definition_model.dart';
import 'package:todo_list/data/repo/battle_repo_impl/local_battle_catalog_repository.dart';
import 'package:todo_list/domain/entities/battle_config.dart';
import 'package:todo_list/domain/entities/battle_enums.dart';
import 'package:todo_list/domain/entities/battle_timeline.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_placement.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';
import 'package:todo_list/domain/entities/battle_unit_state.dart';
import 'package:todo_list/domain/services/battle_simulator.dart';

void main() {
  group('BattleUnitDefinitionModel', () {
    test('parses unit json into entity with icon and skills', () {
      final BattleUnitDefinitionModel model =
          BattleUnitDefinitionModel.fromJson(<String, dynamic>{
            'id': 'templar',
            'name': 'Templar',
            'shortCode': 'TMP',
            'iconKey': 'soldier',
            'attack': 2,
            'health': 7,
            'skills': <Map<String, dynamic>>[
              <String, dynamic>{
                'effectType': 'heal',
                'amount': 2,
                'targetKey': 'ally_in_front',
              },
            ],
          });

      final BattleUnitDefinitionEntity entity = model.toEntity();

      expect(entity.id, 'templar');
      expect(entity.iconKey, 'soldier');
      expect(entity.attack, 2);
      expect(entity.health, 7);
      expect(entity.skills, hasLength(1));
      expect(entity.skills.single.effectType, BattleSkillEffectType.heal);
      expect(entity.skills.single.targetKey, BattleSkillTargetKey.allyInFront);
    });
  });

  group('LocalBattleCatalogRepository', () {
    test('save update and delete roundtrip through local json file', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'battle_catalog_test',
      );
      final String filePath = '${tempDir.path}/units.json';
      final File file = File(filePath);
      await file.writeAsString('[]\n');

      final LocalBattleCatalogRepository repository =
          LocalBattleCatalogRepository(filePathOverride: filePath);

      final BattleUnitDefinitionEntity unit = _definition(
        id: 'guardian',
        name: 'Guardian',
        shortCode: 'GDN',
        iconKey: 'soldier',
        attack: 2,
        health: 8,
        skills: const <BattleUnitSkillEntity>[
          BattleUnitSkillEntity(
            effectType: BattleSkillEffectType.heal,
            amount: 1,
            targetKey: BattleSkillTargetKey.adjacentAllies,
          ),
        ],
      );

      await repository.saveUnitDefinition(unit);
      List<BattleUnitDefinitionEntity> units = await repository
          .getUnitDefinitions();
      expect(units, hasLength(1));
      expect(units.single.name, 'Guardian');
      expect(
        units.single.skills.single.targetKey,
        BattleSkillTargetKey.adjacentAllies,
      );

      await repository.saveUnitDefinition(
        unit.copyWith(name: 'Guardian Prime', attack: 4),
      );
      units = await repository.getUnitDefinitions();
      expect(units, hasLength(1));
      expect(units.single.name, 'Guardian Prime');
      expect(units.single.attack, 4);

      await repository.deleteUnitDefinition(unit.id);
      units = await repository.getUnitDefinitions();
      expect(units, isEmpty);

      await tempDir.delete(recursive: true);
    });
  });

  group('BattleSimulator', () {
    late BattleSimulator simulator;
    const BattleConfigEntity battleConfig = BattleConfigEntity.battle(
      columns: 8,
    );

    setUp(() {
      simulator = BattleSimulator();
    });

    test('cleanup buff does not change the current turn attack', () {
      final BattleUnitDefinitionEntity buffer = _definition(
        id: 'buffer',
        name: 'Buffer',
        shortCode: 'BUF',
        iconKey: 'banner',
        attack: 1,
        health: 4,
        skills: const <BattleUnitSkillEntity>[
          BattleUnitSkillEntity(
            effectType: BattleSkillEffectType.buffAttack,
            amount: 2,
            targetKey: BattleSkillTargetKey.allyInFront,
          ),
        ],
      );
      final BattleUnitDefinitionEntity soldier = _definition(
        id: 'soldier',
        name: 'Soldier',
        shortCode: 'SOL',
        iconKey: 'soldier',
        attack: 1,
        health: 6,
      );
      final BattleUnitDefinitionEntity defender = _definition(
        id: 'defender',
        name: 'Defender',
        shortCode: 'DEF',
        iconKey: 'soldier',
        attack: 1,
        health: 10,
      );

      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'buffer',
            row: 1,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'soldier',
            row: 2,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'defender',
            row: 3,
            column: 0,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'buffer': buffer,
          'soldier': soldier,
          'defender': defender,
        },
      );

      final BattleUnitStateEntity firstTurnDefender = _unitFor(
        timeline.snapshots[1],
        'defender',
        ArmySide.armyB,
      );
      final BattleUnitStateEntity secondTurnDefender = _unitFor(
        timeline.snapshots[2],
        'defender',
        ArmySide.armyB,
      );

      expect(firstTurnDefender.currentHealth, 9);
      expect(secondTurnDefender.currentHealth, 6);
    });

    test('cleanup heal resolves after attack damage', () {
      final BattleUnitDefinitionEntity healer = _definition(
        id: 'healer',
        name: 'Healer',
        shortCode: 'HLR',
        iconKey: 'healer',
        attack: 1,
        health: 4,
        skills: const <BattleUnitSkillEntity>[
          BattleUnitSkillEntity(
            effectType: BattleSkillEffectType.heal,
            amount: 1,
            targetKey: BattleSkillTargetKey.allyInFront,
          ),
        ],
      );
      final BattleUnitDefinitionEntity ally = _definition(
        id: 'ally',
        name: 'Ally',
        shortCode: 'ALY',
        iconKey: 'soldier',
        attack: 2,
        health: 5,
      );
      final BattleUnitDefinitionEntity enemy = _definition(
        id: 'enemy',
        name: 'Enemy',
        shortCode: 'ENY',
        iconKey: 'soldier',
        attack: 3,
        health: 6,
      );

      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'healer',
            row: 1,
            column: 1,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'ally',
            row: 2,
            column: 1,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'enemy',
            row: 3,
            column: 1,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'healer': healer,
          'ally': ally,
          'enemy': enemy,
        },
      );

      final BattleUnitStateEntity allyAfterTurn = _unitFor(
        timeline.snapshots[1],
        'ally',
        ArmySide.armyA,
      );
      final BattleUnitStateEntity enemyAfterTurn = _unitFor(
        timeline.snapshots[1],
        'enemy',
        ArmySide.armyB,
      );

      expect(allyAfterTurn.currentHealth, 3);
      expect(enemyAfterTurn.currentHealth, 4);
    });

    test(
      'a unit killed by queued basic damage still resolves its cleanup skill',
      () {
        final BattleUnitDefinitionEntity bomber = _definition(
          id: 'bomber',
          name: 'Bomber',
          shortCode: 'BMB',
          iconKey: 'mage',
          attack: 1,
          health: 1,
          skills: const <BattleUnitSkillEntity>[
            BattleUnitSkillEntity(
              effectType: BattleSkillEffectType.damage,
              amount: 2,
              targetKey: BattleSkillTargetKey.adjacentEnemies,
            ),
          ],
        );
        final BattleUnitDefinitionEntity enemy = _definition(
          id: 'enemy',
          name: 'Enemy',
          shortCode: 'ENY',
          iconKey: 'soldier',
          attack: 1,
          health: 6,
        );
        final BattleUnitDefinitionEntity flankEnemy = _definition(
          id: 'flank_enemy',
          name: 'Flank Enemy',
          shortCode: 'FLK',
          iconKey: 'soldier',
          attack: 1,
          health: 5,
        );

        final BattleTimelineEntity timeline = simulator.simulate(
          config: battleConfig,
          placements: const <BattleUnitPlacementEntity>[
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyA,
              definitionId: 'bomber',
              row: 1,
              column: 1,
            ),
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: 'enemy',
              row: 2,
              column: 1,
            ),
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: 'flank_enemy',
              row: 2,
              column: 2,
            ),
          ],
          definitions: <String, BattleUnitDefinitionEntity>{
            'bomber': bomber,
            'enemy': enemy,
            'flank_enemy': flankEnemy,
          },
        );

        final BattleUnitStateEntity enemyAfterTurn = _unitFor(
          timeline.snapshots[1],
          'enemy',
          ArmySide.armyB,
        );
        final BattleUnitStateEntity flankEnemyAfterTurn = _unitFor(
          timeline.snapshots[1],
          'flank_enemy',
          ArmySide.armyB,
        );

        expect(
          timeline.snapshots[1].units.any(
            (BattleUnitStateEntity unit) => unit.definitionId == 'bomber',
          ),
          isFalse,
        );
        expect(enemyAfterTurn.currentHealth, 3);
        expect(flankEnemyAfterTurn.currentHealth, 3);
      },
    );

    test(
      'support unit still uses the basic attack if an enemy is in front',
      () {
        final BattleUnitDefinitionEntity healer = _definition(
          id: 'healer',
          name: 'Healer',
          shortCode: 'HLR',
          iconKey: 'healer',
          attack: 1,
          health: 4,
          skills: const <BattleUnitSkillEntity>[
            BattleUnitSkillEntity(
              effectType: BattleSkillEffectType.heal,
              amount: 1,
              targetKey: BattleSkillTargetKey.allyInFront,
            ),
          ],
        );
        final BattleUnitDefinitionEntity enemy = _definition(
          id: 'enemy',
          name: 'Enemy',
          shortCode: 'ENY',
          iconKey: 'soldier',
          attack: 1,
          health: 5,
        );

        final BattleTimelineEntity timeline = simulator.simulate(
          config: battleConfig,
          placements: const <BattleUnitPlacementEntity>[
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyA,
              definitionId: 'healer',
              row: 1,
              column: 1,
            ),
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: 'enemy',
              row: 2,
              column: 1,
            ),
          ],
          definitions: <String, BattleUnitDefinitionEntity>{
            'healer': healer,
            'enemy': enemy,
          },
        );

        final BattleUnitStateEntity enemyAfterTurn = _unitFor(
          timeline.snapshots[1],
          'enemy',
          ArmySide.armyB,
        );

        expect(enemyAfterTurn.currentHealth, 4);
      },
    );

    test('attacker wins if both armies die in the same action phase', () {
      final BattleUnitDefinitionEntity striker = _definition(
        id: 'striker',
        name: 'Striker',
        shortCode: 'STK',
        iconKey: 'soldier',
        attack: 3,
        health: 1,
      );

      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'striker',
            row: 2,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'striker',
            row: 3,
            column: 0,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{'striker': striker},
      );

      expect(timeline.result.winner, ArmySide.armyA);
      expect(timeline.result.resolution, BattleResolution.attackerVictory);
      expect(timeline.snapshots.last.units, isEmpty);
    });

    test('only attackers advance and breakthrough wins immediately', () {
      final BattleUnitDefinitionEntity scout = _definition(
        id: 'scout',
        name: 'Scout',
        shortCode: 'SCT',
        iconKey: 'ranged',
        attack: 1,
        health: 3,
      );
      final BattleUnitDefinitionEntity idleDefender = _definition(
        id: 'idle',
        name: 'Idle',
        shortCode: 'IDL',
        iconKey: 'soldier',
        attack: 1,
        health: 3,
      );

      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'scout',
            row: 6,
            column: 2,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'idle',
            row: 7,
            column: 5,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'scout': scout,
          'idle': idleDefender,
        },
      );

      expect(timeline.result.winner, ArmySide.armyA);
      expect(timeline.result.resolution, BattleResolution.attackerVictory);
      expect(
        timeline.snapshots.last.units.any(
          (BattleUnitStateEntity unit) =>
              unit.armySide == ArmySide.armyA && unit.row == 7,
        ),
        isTrue,
      );
      expect(
        timeline.snapshots.last.units.any(
          (BattleUnitStateEntity unit) =>
              unit.armySide == ArmySide.armyB && unit.row != 7,
        ),
        isFalse,
      );
    });

    test('tournament config uses dynamic breakthrough row', () {
      final BattleConfigEntity tournamentConfig = BattleConfigEntity.tournament(
        preset: TournamentPreset.wide2x4,
      );
      final BattleUnitDefinitionEntity scout = _definition(
        id: 'scout',
        name: 'Scout',
        shortCode: 'SCT',
        iconKey: 'ranged',
        attack: 1,
        health: 3,
      );
      final BattleUnitDefinitionEntity defender = _definition(
        id: 'defender',
        name: 'Defender',
        shortCode: 'DEF',
        iconKey: 'soldier',
        attack: 1,
        health: 4,
      );

      final BattleTimelineEntity timeline = simulator.simulate(
        config: tournamentConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'scout',
            row: 0,
            column: 1,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'defender',
            row: 1,
            column: 0,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'scout': scout,
          'defender': defender,
        },
      );

      expect(timeline.result.winner, ArmySide.armyA);
      expect(
        timeline.snapshots.last.units.any(
          (BattleUnitStateEntity unit) =>
              unit.armySide == ArmySide.armyA && unit.row == 1,
        ),
        isTrue,
      );
    });
  });
}

BattleUnitDefinitionEntity _definition({
  required String id,
  required String name,
  required String shortCode,
  required String iconKey,
  required int attack,
  required int health,
  List<BattleUnitSkillEntity> skills = const <BattleUnitSkillEntity>[],
}) {
  return BattleUnitDefinitionEntity(
    id: id,
    name: name,
    shortCode: shortCode,
    iconKey: iconKey,
    attack: attack,
    health: health,
    skills: skills,
  );
}

BattleUnitStateEntity _unitFor(
  BattleSnapshotEntity snapshot,
  String definitionId,
  ArmySide side,
) {
  return snapshot.units.singleWhere(
    (BattleUnitStateEntity unit) =>
        unit.definitionId == definitionId && unit.armySide == side,
  );
}
