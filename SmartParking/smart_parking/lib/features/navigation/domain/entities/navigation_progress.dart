import 'navigation_location.dart';

class NavigationProgress {
  final NavigationLocation snappedLocation;

  final int segmentIndex;

  final double traveledDistance;

  final double remainingDistance;

  final double distanceFromRoute;

  const NavigationProgress({
    required this.snappedLocation,
    required this.segmentIndex,
    required this.traveledDistance,
    required this.remainingDistance,
    required this.distanceFromRoute,
  });
}