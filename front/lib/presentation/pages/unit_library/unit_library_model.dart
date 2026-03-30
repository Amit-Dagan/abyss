import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';

enum UnitLibraryStatus { initial, loading, ready, failure }

class UnitLibraryModel extends Model {
  UnitLibraryStatus status;
  List<BattleUnitDefinitionEntity> units;
  String? errorMessage;

  UnitLibraryModel({
    this.status = UnitLibraryStatus.initial,
    this.units = const <BattleUnitDefinitionEntity>[],
    this.errorMessage,
  }) {
    appBarTitle = 'UNIT LIBRARY';
  }
}
