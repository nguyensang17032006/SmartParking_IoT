/// Physical bay locations, independent of Flutter and screen coordinates.
enum ParkingMapRow { top, bottom }

class ParkingBayLocation {
  final ParkingMapRow row;
  final int column;
  const ParkingBayLocation({required this.row, required this.column});

  @override
  bool operator ==(Object other) =>
      other is ParkingBayLocation && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);
}

class ParkingMapLayout {
  final List<String> topRowCodes;
  final List<String> bottomRowCodes;

  ParkingMapLayout({
    required Iterable<String> topRowCodes,
    required Iterable<String> bottomRowCodes,
  }) : topRowCodes = List.unmodifiable(topRowCodes),
       bottomRowCodes = List.unmodifiable(bottomRowCodes) {
    final codes = [...this.topRowCodes, ...this.bottomRowCodes];
    if (codes.any((code) => code.trim().isEmpty)) {
      throw ArgumentError('Mã ô trên sơ đồ không được để trống.');
    }
    if (codes.toSet().length != codes.length) {
      throw ArgumentError('Mỗi mã ô chỉ được đặt ở một vị trí trên sơ đồ.');
    }
  }

  int get columnCount {
    final count = topRowCodes.length > bottomRowCodes.length
        ? topRowCodes.length
        : bottomRowCodes.length;
    return count < 1 ? 1 : count;
  }

  ParkingBayLocation? locationOf(String code) {
    final topColumn = topRowCodes.indexOf(code);
    if (topColumn >= 0) {
      return ParkingBayLocation(row: ParkingMapRow.top, column: topColumn);
    }
    final bottomColumn = bottomRowCodes.indexOf(code);
    if (bottomColumn >= 0) {
      return ParkingBayLocation(
        row: ParkingMapRow.bottom,
        column: bottomColumn,
      );
    }
    return null;
  }
}
