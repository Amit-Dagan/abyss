import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';

enum UnitEditorStatus { initial, loading, ready, saving, failure }

class UnitEditorModel extends Model {
  UnitEditorStatus status;
  bool isExistingUnit;
  String? unitId;
  String name;
  String shortCode;
  String iconKey;
  int attack;
  int health;
  List<BattleUnitSkillEntity> skills;
  String? errorMessage;

  UnitEditorModel({
    this.status = UnitEditorStatus.initial,
    this.isExistingUnit = false,
    this.unitId,
    this.name = '',
    this.shortCode = '',
    this.iconKey = 'soldier',
    this.attack = 1,
    this.health = 1,
    this.skills = const <BattleUnitSkillEntity>[],
    this.errorMessage,
  }) {
    appBarTitle = 'UNIT EDITOR';
  }
}
