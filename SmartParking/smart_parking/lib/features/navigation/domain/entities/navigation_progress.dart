import 'navigation_location.dart';

class NavigationProgress {
  final NavigationLocation snappedLocation;

  final int segmentIndex;

  final double segmentFraction;

  final double traveledDistance;

  final double remainingDistance;

  final double distanceFromRoute;

  final double nearestRouteDistance;

  const NavigationProgress({
    required this.snappedLocation,
    required this.segmentIndex,
    this.segmentFraction = 0,
    required this.traveledDistance,
    required this.remainingDistance,
    required this.distanceFromRoute,
    required this.nearestRouteDistance,
  });
}