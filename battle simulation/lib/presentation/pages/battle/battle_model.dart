import 'package:todo_list/domain/entities/battle_config.dart';
import 'package:mvvm_remepy/view_model.dart';
import 'package:todo_list/domain/entities/battle_timeline.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/domain/entities/battle_unit_placement.dart';

enum BattleScreenStatus { initial, loading, ready, failure }

enum BattlePhase { setup, replay }

class BattleModel extends Model {
  BattleScreenStatus status;
  BattlePhase phase;
  BattleConfigEntity battleConfig;
  List<BattleUnitDefinitionEntity> definitions;
  List<BattleUnitPlacementEntity> placements;
  BattleTimelineEntity? timeline;
  int currentSnapshotIndex;
  bool isAutoPlaying;
  String? errorMessage;

  BattleModel({
    this.status = BattleScreenStatus.initial,
    this.phase = BattlePhase.setup,
    this.battleConfig = BattleConfigEntity.fallback,
    this.definitions = const [],
    this.placements = const [],
    this.timeline,
    this.currentSnapshotIndex = 0,
    this.isAutoPlaying = false,
    this.errorMessage,
  }) {
    appBarTitle = 'BATTLE SIM';
  }
}
