enum NavigationManeuver {
  straight,
  turnLeft,
  turnRight,
  slightLeft,
  slightRight,
  sharpLeft,
  sharpRight,
  uTurn,
  roundabout,
  merge,
  arrive,
  depart,
  unknown,
}

class NavigationInstruction {
  final NavigationManeuver maneuver;

  final String instruction;

  final String streetName;

  final double distanceToManeuver;

  final int stepIndex;

  // Tên đường đang di chuyển.
  final String currentStreetName;

  // Hướng dẫn sau thao tác hiện tại.
  final NavigationInstruction? nextInstruction;

  const NavigationInstruction({
    required this.maneuver,
    required this.instruction,
    required this.streetName,
    required this.distanceToManeuver,
    required this.stepIndex,
    this.currentStreetName = '',
    this.nextInstruction,
  });
}
