import '../entities/navigation_location.dart';
import '../entities/navigation_progress.dart';

import 'navigation_distance_service.dart';
import 'map_matching_service.dart';

class NavigationProgressService {
  final NavigationDistanceService distanceService;

  final MapMatchingService mapMatchingService;

  const NavigationProgressService({
    this.distanceService = const NavigationDistanceService(),
    this.mapMatchingService = const MapMatchingService(),
  });

  NavigationProgress calculateProgress({
    required NavigationLocation currentLocation,
    required List<NavigationLocation> routePoints,
    NavigationProgress? previousProgress,
  }) {
    if (routePoints.length < 2) {
      throw ArgumentError('Tuyến đường phải có ít nhất 2 điểm.');
    }

    // 1. Xác định vị trí trên tuyến đường.
    final matchingResult = mapMatchingService.match(
      currentLocation: currentLocation,
      routePoints: routePoints,
      previousProgress: previousProgress,
    );

    // 2. Tính tổng chiều dài tuyến đường.
    final totalDistance = distanceService.calculatePathDistance(routePoints);

    // 3. Xác định quãng đường đã đi.
    final traveledDistance = matchingResult.traveledDistance
        .clamp(0.0, totalDistance)
        .toDouble();

    // 4. Tính quãng đường còn lại.
    final remainingDistance = totalDistance - traveledDistance;

    // 5. Trả về tiến độ hiện tại.
    return NavigationProgress(
      snappedLocation: matchingResult.snappedLocation,
      segmentIndex: matchingResult.segmentIndex,
      segmentFraction: matchingResult.segmentFraction,
      traveledDistance: traveledDistance,
      remainingDistance: remainingDistance,
      distanceFromRoute: matchingResult.distanceFromRoute,
      nearestRouteDistance: matchingResult.nearestRouteDistance,
    );
  }
}
