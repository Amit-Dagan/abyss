import 'package:todo_list/domain/entities/battle_enums.dart';
import 'package:todo_list/domain/entities/battle_unit_state.dart';

enum BattleResolution { attackerVictory, defenderVictory }

class BattleSnapshotEntity {
  final int turn;
  final List<BattleUnitStateEntity> units;
  final List<String> events;

  const BattleSnapshotEntity({
    required this.turn,
    required this.units,
    required this.events,
  });
}

class BattleResultEntity {
  final BattleResolution resolution;
  final ArmySide winner;
  final String summary;

  const BattleResultEntity({
    required this.resolution,
    required this.winner,
    required this.summary,
  });
}

class BattleTimelineEntity {
  final List<BattleSnapshotEntity> snapshots;
  final BattleResultEntity result;

  const BattleTimelineEntity({required this.snapshots, required this.result});
}
