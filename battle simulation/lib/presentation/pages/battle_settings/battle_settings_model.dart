import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/battle_config.dart';

class BattleSettingsModel extends Model {
  BattleMode selectedMode;
  int battleColumns;
  TournamentPreset selectedTournamentPreset;

  BattleSettingsModel({
    this.selectedMode = BattleMode.battle,
    this.battleColumns = 8,
    this.selectedTournamentPreset = TournamentPreset.wide2x4,
  }) {
    appBarTitle = 'BATTLE SETTINGS';
  }
}
