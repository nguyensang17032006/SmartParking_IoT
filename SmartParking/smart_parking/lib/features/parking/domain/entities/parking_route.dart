import 'parking_map_layout.dart';

/// Logical route: enter from the left, reach this column, turn into this row.
/// The presentation layer converts it into a line on the screen.
class ParkingRoute {
  final String slotCode;
  final ParkingBayLocation destination;
  const ParkingRoute({required this.slotCode, required this.destination});

  @override
  bool operator ==(Object other) =>
      other is ParkingRoute &&
      slotCode == other.slotCode &&
      destination == other.destination;

  @override
  int get hashCode => Object.hash(slotCode, destination);
}
