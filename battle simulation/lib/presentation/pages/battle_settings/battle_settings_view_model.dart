import 'package:mvvm_remepy/observer/observer.dart';
import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/battle_config.dart';
import 'package:todo_list/presentation/pages/battle_settings/battle_settings_model.dart';

class BattleSettingsViewModel extends ViewModel<BattleSettingsModel> {
  BattleSettingsViewModel({required super.model});

  BattleConfigEntity get selectedConfig =>
      model.selectedMode == BattleMode.battle
      ? BattleConfigEntity.battle(columns: model.battleColumns)
      : BattleConfigEntity.tournament(preset: model.selectedTournamentPreset);

  void selectMode(BattleMode mode) {
    model.selectedMode = mode;
    notify();
  }

  void selectBattleColumns(int columns) {
    model.battleColumns = columns;
    notify();
  }

  void selectTournamentPreset(TournamentPreset preset) {
    model.selectedTournamentPreset = preset;
    notify();
  }

  void startBattle() {
    notifyNavigate(
      NavigateModel(routeName: '/battle', arguments: selectedConfig),
    );
  }
}
