import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/battle_unit_skill.dart';

enum UnitEditorStatus { initial, loading, ready, saving, failure }

class UnitEditorModel extends Model {
  UnitEditorStatus status;
  bool isExistingUnit;
  String? unitId;
  String name;
  String iconKey;
  int attack;
  int health;
  BattleAttackPatternKey attackPattern;
  int attackPatternAmount;
  List<BattleOnHitEffectEntity> onHitEffects;
  List<BattleTargetedSkillEntity> targetedSkills;
  List<BattlePassiveSkillEntity> passiveSkills;
  String? errorMessage;

  UnitEditorModel({
    this.status = UnitEditorStatus.initial,
    this.isExistingUnit = false,
    this.unitId,
    this.name = '',
    this.iconKey = 'soldier',
    this.attack = 1,
    this.health = 1,
    this.attackPattern = BattleAttackPatternKey.front,
    this.attackPatternAmount = 1,
    this.onHitEffects = const <BattleOnHitEffectEntity>[],
    this.targetedSkills = const <BattleTargetedSkillEntity>[],
    this.passiveSkills = const <BattlePassiveSkillEntity>[],
    this.errorMessage,
  }) {
    appBarTitle = 'UNIT EDITOR';
  }
}
