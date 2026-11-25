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

  const NavigationInstruction({
    required this.maneuver,
    required this.instruction,
    required this.streetName,
    required this.distanceToManeuver,
    required this.stepIndex,
  });
}