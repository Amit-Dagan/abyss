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
    test('parses the split unit schema', () {
      final BattleUnitDefinitionModel model =
          BattleUnitDefinitionModel.fromJson(<String, dynamic>{
            'id': 'warden',
            'name': 'Warden',
            'iconKey': 'soldier',
            'attack': 2,
            'health': 7,
            'attackPattern': 'range',
            'attackPatternAmount': 3,
            'onHitEffects': <Map<String, dynamic>>[
              <String, dynamic>{'effectType': 'poison', 'amount': 1},
            ],
            'targetedSkills': <Map<String, dynamic>>[
              <String, dynamic>{
                'effectType': 'heal',
                'amount': 2,
                'targetKey': 'adjacent_allies',
              },
            ],
            'passiveSkills': <Map<String, dynamic>>[
              <String, dynamic>{
                'effectType': 'taunt',
                'targetKey': 'adjacent_allies',
              },
            ],
          });

      final BattleUnitDefinitionEntity entity = model.toEntity();

      expect(entity.attackPattern, BattleAttackPatternKey.range);
      expect(entity.attackPatternAmount, 3);
      expect(entity.onHitEffects.single.type, BattleOnHitEffectType.poison);
      expect(entity.targetedSkills.single.type, BattleTargetedSkillType.heal);
      expect(
        entity.targetedSkills.single.targetKey,
        BattleTargetKey.adjacentAllies,
      );
      expect(entity.passiveSkills.single.type, BattlePassiveSkillType.taunt);
    });
  });

  group('LocalBattleCatalogRepository', () {
    test('roundtrips the new unit schema through local json', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'battle_catalog_test',
      );
      final String filePath = '${tempDir.path}/units.json';
      await File(filePath).writeAsString('[]\n');

      final LocalBattleCatalogRepository repository =
          LocalBattleCatalogRepository(filePathOverride: filePath);

      final BattleUnitDefinitionEntity unit = _definition(
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

      await repository.saveUnitDefinition(unit);
      final List<BattleUnitDefinitionEntity> units = await repository
          .getUnitDefinitions();

      expect(units, hasLength(1));
      expect(units.single.attackPattern, BattleAttackPatternKey.range);
      expect(units.single.attackPatternAmount, 4);
      expect(units.single.onHitEffects.single.type, BattleOnHitEffectType.fire);
      expect(
        units.single.targetedSkills.single.targetKey,
        BattleTargetKey.adjacentAllies,
      );
      expect(
        units.single.passiveSkills.single.type,
        BattlePassiveSkillType.rage,
      );

      await tempDir.delete(recursive: true);
    });
  });

  group('BattleSimulator', () {
    late BattleSimulator simulator;
    const BattleConfigEntity battleConfig = BattleConfigEntity.battle(
      columns: 4,
    );

    setUp(() {
      simulator = BattleSimulator();
    });

    test('cleanup buff changes future turns only', () {
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
          'buffer': _definition(
            id: 'buffer',
            name: 'Buffer',
            iconKey: 'banner',
            attack: 1,
            health: 4,
            targetedSkills: const <BattleTargetedSkillEntity>[
              BattleTargetedSkillEntity(
                type: BattleTargetedSkillType.buffAttack,
                amount: 2,
                targetKey: BattleTargetKey.frontAlly,
              ),
            ],
          ),
          'soldier': _definition(
            id: 'soldier',
            name: 'Soldier',
            iconKey: 'soldier',
            attack: 1,
            health: 6,
          ),
          'defender': _definition(
            id: 'defender',
            name: 'Defender',
            iconKey: 'soldier',
            attack: 1,
            health: 10,
          ),
        },
      );

      expect(_unitFor(timeline.snapshots[1], 'defender').currentHealth, 9);
      expect(_unitFor(timeline.snapshots[2], 'defender').currentHealth, 6);
      expect(_unitFor(timeline.snapshots[2], 'soldier').currentAttack, 5);
      expect(_unitFor(timeline.snapshots[2], 'soldier').isEnraged, isTrue);
    });

    test(
      'range attacks the first enemy in the same column within its limit',
      () {
        final BattleTimelineEntity timeline = simulator.simulate(
          config: battleConfig,
          placements: const <BattleUnitPlacementEntity>[
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyA,
              definitionId: 'ranger',
              row: 1,
              column: 0,
            ),
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: 'target',
              row: 4,
              column: 0,
            ),
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: 'target',
              row: 5,
              column: 0,
            ),
          ],
          definitions: <String, BattleUnitDefinitionEntity>{
            'ranger': _definition(
              id: 'ranger',
              name: 'Ranger',
              iconKey: 'ranged',
              attack: 2,
              health: 4,
              attackPattern: BattleAttackPatternKey.range,
              attackPatternAmount: 3,
            ),
            'target': _definition(
              id: 'target',
              name: 'Target',
              iconKey: 'soldier',
              attack: 0,
              health: 5,
            ),
          },
        );

        final BattleSnapshotEntity firstTurn = timeline.snapshots[1];
        final List<BattleUnitStateEntity> targets =
            firstTurn.units
                .where(
                  (BattleUnitStateEntity unit) => unit.definitionId == 'target',
                )
                .toList(growable: false)
              ..sort(
                (BattleUnitStateEntity a, BattleUnitStateEntity b) =>
                    a.row.compareTo(b.row),
              );

        expect(targets[0].currentHealth, 3);
        expect(targets[1].currentHealth, 5);
      },
    );

    test(
      'cleave attacks the full front row and on-hit poison applies to each hit',
      () {
        final BattleTimelineEntity timeline = simulator.simulate(
          config: battleConfig,
          placements: const <BattleUnitPlacementEntity>[
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyA,
              definitionId: 'cleaver',
              row: 2,
              column: 1,
            ),
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: 'target',
              row: 3,
              column: 0,
            ),
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: 'target',
              row: 3,
              column: 1,
            ),
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: 'target',
              row: 3,
              column: 2,
            ),
          ],
          definitions: <String, BattleUnitDefinitionEntity>{
            'cleaver': _definition(
              id: 'cleaver',
              name: 'Cleaver',
              iconKey: 'ranged',
              attack: 1,
              health: 6,
              attackPattern: BattleAttackPatternKey.cleave,
              onHitEffects: const <BattleOnHitEffectEntity>[
                BattleOnHitEffectEntity(
                  type: BattleOnHitEffectType.poison,
                  amount: 1,
                ),
              ],
            ),
            'target': _definition(
              id: 'target',
              name: 'Target',
              iconKey: 'soldier',
              attack: 1,
              health: 5,
            ),
          },
        );

        final BattleSnapshotEntity firstTurn = timeline.snapshots[1];
        for (final BattleUnitStateEntity unit in firstTurn.units.where(
          (BattleUnitStateEntity unit) => unit.definitionId == 'target',
        )) {
          expect(unit.currentHealth, 3);
        }
      },
    );

    test('taunt redirects attack damage and attached riders', () {
      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'attacker',
            row: 2,
            column: 1,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'tank',
            row: 3,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'ally',
            row: 3,
            column: 1,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'attacker': _definition(
            id: 'attacker',
            name: 'Attacker',
            iconKey: 'beast',
            attack: 2,
            health: 5,
            onHitEffects: const <BattleOnHitEffectEntity>[
              BattleOnHitEffectEntity(
                type: BattleOnHitEffectType.poison,
                amount: 1,
              ),
            ],
          ),
          'tank': _definition(
            id: 'tank',
            name: 'Tank',
            iconKey: 'soldier',
            attack: 1,
            health: 8,
            passiveSkills: const <BattlePassiveSkillEntity>[
              BattlePassiveSkillEntity(
                type: BattlePassiveSkillType.taunt,
                targetKey: BattleTargetKey.adjacentAllies,
              ),
            ],
          ),
          'ally': _definition(
            id: 'ally',
            name: 'Ally',
            iconKey: 'healer',
            attack: 1,
            health: 5,
          ),
        },
      );

      expect(_unitFor(timeline.snapshots[1], 'tank').currentHealth, 5);
      expect(_unitFor(timeline.snapshots[1], 'ally').currentHealth, 5);
      expect(_unitFor(timeline.snapshots[1], 'tank').hasTaunt, isTrue);
      expect(
        _unitFor(timeline.snapshots[1], 'tank').poisonStacks,
        greaterThan(0),
      );
    });

    test('stun skips the next turn only', () {
      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'stunner',
            row: 2,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'victim',
            row: 3,
            column: 0,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'stunner': _definition(
            id: 'stunner',
            name: 'Stunner',
            iconKey: 'mage',
            attack: 1,
            health: 4,
            onHitEffects: const <BattleOnHitEffectEntity>[
              BattleOnHitEffectEntity(
                type: BattleOnHitEffectType.stun,
                amount: 1,
              ),
            ],
          ),
          'victim': _definition(
            id: 'victim',
            name: 'Victim',
            iconKey: 'soldier',
            attack: 1,
            health: 4,
          ),
        },
      );

      expect(_unitFor(timeline.snapshots[1], 'victim').currentHealth, 3);
      expect(_unitFor(timeline.snapshots[1], 'victim').isStunned, isTrue);
      expect(_unitFor(timeline.snapshots[2], 'victim').currentHealth, 2);
      expect(_unitFor(timeline.snapshots[2], 'stunner').currentHealth, 3);
    });

    test('fire ticks immediately and decreases each cleanup', () {
      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'burner',
            row: 2,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'target',
            row: 3,
            column: 0,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'burner': _definition(
            id: 'burner',
            name: 'Burner',
            iconKey: 'mage',
            attack: 1,
            health: 4,
            targetedSkills: const <BattleTargetedSkillEntity>[
              BattleTargetedSkillEntity(
                type: BattleTargetedSkillType.fire,
                amount: 3,
                targetKey: BattleTargetKey.frontEnemy,
              ),
            ],
          ),
          'target': _definition(
            id: 'target',
            name: 'Target',
            iconKey: 'soldier',
            attack: 1,
            health: 12,
          ),
        },
      );

      expect(_unitFor(timeline.snapshots[1], 'target').currentHealth, 8);
      expect(
        _unitFor(timeline.snapshots[1], 'target').fireStacks,
        greaterThan(0),
      );
      expect(_unitFor(timeline.snapshots[2], 'target').currentHealth, 2);
    });

    test('poison ticks immediately and increases each cleanup', () {
      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'poisoner',
            row: 2,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'target',
            row: 3,
            column: 0,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'poisoner': _definition(
            id: 'poisoner',
            name: 'Poisoner',
            iconKey: 'beast',
            attack: 1,
            health: 4,
            targetedSkills: const <BattleTargetedSkillEntity>[
              BattleTargetedSkillEntity(
                type: BattleTargetedSkillType.poison,
                amount: 1,
                targetKey: BattleTargetKey.frontEnemy,
              ),
            ],
          ),
          'target': _definition(
            id: 'target',
            name: 'Target',
            iconKey: 'soldier',
            attack: 1,
            health: 12,
          ),
        },
      );

      expect(_unitFor(timeline.snapshots[1], 'target').currentHealth, 10);
      expect(
        _unitFor(timeline.snapshots[1], 'target').poisonStacks,
        greaterThan(0),
      );
      expect(_unitFor(timeline.snapshots[2], 'target').currentHealth, 6);
    });

    test(
      'rage grants attack after taking damage and only matters on later turns',
      () {
        final BattleTimelineEntity timeline = simulator.simulate(
          config: battleConfig,
          placements: const <BattleUnitPlacementEntity>[
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyA,
              definitionId: 'rager',
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
            'rager': _definition(
              id: 'rager',
              name: 'Rager',
              iconKey: 'soldier',
              attack: 1,
              health: 6,
              passiveSkills: const <BattlePassiveSkillEntity>[
                BattlePassiveSkillEntity(
                  type: BattlePassiveSkillType.rage,
                  amount: 2,
                ),
              ],
            ),
            'defender': _definition(
              id: 'defender',
              name: 'Defender',
              iconKey: 'soldier',
              attack: 1,
              health: 10,
            ),
          },
        );

        expect(_unitFor(timeline.snapshots[1], 'defender').currentHealth, 9);
        expect(_unitFor(timeline.snapshots[2], 'defender').currentHealth, 6);
      },
    );

    test('summoner revives a fallen ally in its original tile', () {
      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'summoner',
            row: 1,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'ally',
            row: 2,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'enemy',
            row: 3,
            column: 0,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'summoner': _definition(
            id: 'summoner',
            name: 'Summoner',
            iconKey: 'banner',
            attack: 1,
            health: 4,
            passiveSkills: const <BattlePassiveSkillEntity>[
              BattlePassiveSkillEntity(
                type: BattlePassiveSkillType.summoner,
                amount: 1,
              ),
            ],
          ),
          'ally': _definition(
            id: 'ally',
            name: 'Ally',
            iconKey: 'soldier',
            attack: 1,
            health: 1,
          ),
          'enemy': _definition(
            id: 'enemy',
            name: 'Enemy',
            iconKey: 'soldier',
            attack: 2,
            health: 6,
          ),
        },
      );

      final BattleUnitStateEntity revived = _unitFor(
        timeline.snapshots[1],
        'ally',
      );
      expect(revived.row, 2);
      expect(revived.column, 0);
      expect(revived.currentHealth, 1);
    });

    test(
      'knockback resolves before advancing and blocks same-turn movement',
      () {
        final BattleTimelineEntity timeline = simulator.simulate(
          config: BattleConfigEntity.tournament(
            preset: TournamentPreset.lane8x1,
          ),
          placements: const <BattleUnitPlacementEntity>[
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyA,
              definitionId: 'knocker',
              row: 3,
              column: 0,
            ),
            BattleUnitPlacementEntity(
              armySide: ArmySide.armyB,
              definitionId: 'target',
              row: 4,
              column: 0,
            ),
          ],
          definitions: <String, BattleUnitDefinitionEntity>{
            'knocker': _definition(
              id: 'knocker',
              name: 'Knocker',
              iconKey: 'soldier',
              attack: 1,
              health: 5,
              onHitEffects: const <BattleOnHitEffectEntity>[
                BattleOnHitEffectEntity(
                  type: BattleOnHitEffectType.knockback,
                  amount: 1,
                ),
              ],
            ),
            'target': _definition(
              id: 'target',
              name: 'Target',
              iconKey: 'soldier',
              attack: 1,
              health: 5,
            ),
          },
        );

        final BattleUnitStateEntity target = _unitFor(
          timeline.snapshots[1],
          'target',
        );
        expect(target.row, 5);
      },
    );

    test('battle mode breakthrough still wins for red', () {
      final BattleTimelineEntity timeline = simulator.simulate(
        config: battleConfig,
        placements: const <BattleUnitPlacementEntity>[
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyA,
            definitionId: 'runner',
            row: 6,
            column: 0,
          ),
          BattleUnitPlacementEntity(
            armySide: ArmySide.armyB,
            definitionId: 'blocker',
            row: 0,
            column: 3,
          ),
        ],
        definitions: <String, BattleUnitDefinitionEntity>{
          'runner': _definition(
            id: 'runner',
            name: 'Runner',
            iconKey: 'beast',
            attack: 1,
            health: 3,
          ),
          'blocker': _definition(
            id: 'blocker',
            name: 'Blocker',
            iconKey: 'soldier',
            attack: 1,
            health: 3,
          ),
        },
      );

      expect(timeline.result.winner, ArmySide.armyA);
      expect(timeline.result.resolution, BattleResolution.attackerVictory);
      expect(
        timeline.snapshots.last.units.any((unit) => unit.row == 7),
        isTrue,
      );
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

BattleUnitStateEntity _unitFor(
  BattleSnapshotEntity snapshot,
  String definitionId,
) {
  return snapshot.units.firstWhere(
    (BattleUnitStateEntity unit) => unit.definitionId == definitionId,
  );
}
