class BattleCoordinate {
  final int row;
  final int column;

  const BattleCoordinate({required this.row, required this.column});

  BattleCoordinate translate({
    required int rowOffset,
    required int columnOffset,
  }) {
    return BattleCoordinate(
      row: row + rowOffset,
      column: column + columnOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BattleCoordinate &&
        other.row == row &&
        other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => '($row,$column)';
}
