import 'navigation_location.dart';

class NavigationStep {
  final String streetName;
  final String maneuverType;
  final String maneuverModifier;
  final double distance;
  final double duration;
  final NavigationLocation location;

  // Hình dạng của từng bước di chuyển.
  final List<NavigationLocation> geometry;

  // Hướng di chuyển trước và sau thao tác.
  final int? bearingBefore;
  final int? bearingAfter;

  const NavigationStep({
    required this.streetName,
    required this.maneuverType,
    required this.maneuverModifier,
    required this.distance,
    required this.duration,
    required this.location,
    this.geometry = const [],
    this.bearingBefore,
    this.bearingAfter,
  });
}