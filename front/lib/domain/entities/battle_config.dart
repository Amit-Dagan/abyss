import 'package:todo_list/domain/entities/battle_enums.dart';

enum BattleMode { battle, tournament }

extension BattleModeX on BattleMode {
  String get label => switch (this) {
    BattleMode.battle => 'Battle',
    BattleMode.tournament => 'Tournament',
  };
}

enum TournamentPreset { duel2x1, wide2x4, tall4x2, lane8x1 }

extension TournamentPresetX on TournamentPreset {
  int get rows => switch (this) {
    TournamentPreset.duel2x1 => 2,
    TournamentPreset.wide2x4 => 2,
    TournamentPreset.tall4x2 => 4,
    TournamentPreset.lane8x1 => 8,
  };

  int get columns => switch (this) {
    TournamentPreset.duel2x1 => 1,
    TournamentPreset.wide2x4 => 4,
    TournamentPreset.tall4x2 => 2,
    TournamentPreset.lane8x1 => 1,
  };

  String get label => switch (this) {
    TournamentPreset.duel2x1 => '1 vs 1',
    TournamentPreset.wide2x4 => '2 x 4',
    TournamentPreset.tall4x2 => '4 x 2',
    TournamentPreset.lane8x1 => '8 x 1',
  };
}

class BattleConfigEntity {
  final BattleMode mode;
  final int rows;
  final int columns;
  final TournamentPreset? tournamentPreset;

  const BattleConfigEntity({
    required this.mode,
    required this.rows,
    required this.columns,
    this.tournamentPreset,
  });

  const BattleConfigEntity.battle({required this.columns})
    : mode = BattleMode.battle,
      rows = 8,
      tournamentPreset = null;

  BattleConfigEntity.tournament({required TournamentPreset preset})
    : mode = BattleMode.tournament,
      rows = preset.rows,
      columns = preset.columns,
      tournamentPreset = preset;

  static const BattleConfigEntity fallback = BattleConfigEntity.battle(
    columns: 8,
  );

  bool get isBattle => mode == BattleMode.battle;

  bool get isTournament => mode == BattleMode.tournament;

  int get setupRowsPerSide => isBattle ? 3 : rows ~/ 2;

  int get neutralGapRows => isBattle ? 2 : 0;

  String get sizeLabel => '$rows x $columns';

  String get modeLabel => mode.label;

  String get summaryLabel => isBattle
      ? 'Battle mode on a $sizeLabel board'
      : 'Tournament mode on a $sizeLabel board';

  ArmySide? deploymentOwnerForRow(int row) {
    if (row < 0 || row >= rows) {
      return null;
    }

    if (isBattle) {
      if (row < 3) {
        return ArmySide.armyA;
      }
      if (row >= rows - 3) {
        return ArmySide.armyB;
      }
      return null;
    }

    return row < rows ~/ 2 ? ArmySide.armyA : ArmySide.armyB;
  }
}
