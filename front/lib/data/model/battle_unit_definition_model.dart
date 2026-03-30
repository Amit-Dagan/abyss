import 'package:todo_list/data/model/battle_unit_skill_model.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';

class BattleUnitDefinitionModel {
  final String id;
  final String name;
  final String shortCode;
  final String iconKey;
  final int attack;
  final int health;
  final List<BattleUnitSkillModel> skills;

  const BattleUnitDefinitionModel({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.iconKey,
    required this.attack,
    required this.health,
    required this.skills,
  });

  factory BattleUnitDefinitionModel.fromJson(Map<String, dynamic> json) {
    return BattleUnitDefinitionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      shortCode: json['shortCode'] as String,
      iconKey: json['iconKey'] as String,
      attack: json['attack'] as int,
      health: json['health'] as int,
      skills: (json['skills'] as List<dynamic>)
          .map(
            (dynamic skillJson) => BattleUnitSkillModel.fromJson(
              skillJson as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  factory BattleUnitDefinitionModel.fromEntity(
    BattleUnitDefinitionEntity entity,
  ) {
    return BattleUnitDefinitionModel(
      id: entity.id,
      name: entity.name,
      shortCode: entity.shortCode,
      iconKey: entity.iconKey,
      attack: entity.attack,
      health: entity.health,
      skills: entity.skills
          .map(BattleUnitSkillModel.fromEntity)
          .toList(growable: false),
    );
  }

  BattleUnitDefinitionEntity toEntity() {
    return BattleUnitDefinitionEntity(
      id: id,
      name: name,
      shortCode: shortCode,
      iconKey: iconKey,
      attack: attack < 1 ? 1 : attack,
      health: health < 1 ? 1 : health,
      skills: skills
          .map((BattleUnitSkillModel skill) => skill.toEntity())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortCode': shortCode,
      'iconKey': iconKey,
      'attack': attack,
      'health': health,
      'skills': skills
          .map((BattleUnitSkillModel skill) => skill.toJson())
          .toList(),
    };
  }
}
