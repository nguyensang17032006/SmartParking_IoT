import 'navigation_location.dart';

class MapMatchingResult {
  final NavigationLocation snappedLocation;

  final int segmentIndex;

  final double segmentFraction;

  final double distanceFromRoute;

  final double nearestRouteDistance;

  final double traveledDistance;

  final double score;

  const MapMatchingResult({
    required this.snappedLocation,
    required this.segmentIndex,
    required this.segmentFraction,
    required this.distanceFromRoute,
    required this.nearestRouteDistance,
    required this.traveledDistance,
    required this.score,
  });
}