import 'navigation_location.dart';

class NavigationStep {
  final String streetName;
  final String maneuverType;
  final String maneuverModifier;
  final double distance;
  final double duration;
  final NavigationLocation location;

  const NavigationStep({
    required this.streetName,
    required this.maneuverType,
    required this.maneuverModifier,
    required this.distance,
    required this.duration,
    required this.location,
  });
}