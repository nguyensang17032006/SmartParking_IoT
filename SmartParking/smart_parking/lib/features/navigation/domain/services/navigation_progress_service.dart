import 'dart:math' as math;

import '../entities/navigation_location.dart';
import '../entities/navigation_progress.dart';
import 'navigation_distance_service.dart';

class NavigationProgressService {
  final NavigationDistanceService distanceService;

  const NavigationProgressService({
    this.distanceService =
        const NavigationDistanceService(),
  });

  static const double _earthRadius = 6371000;

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  NavigationLocation _projectPointToSegment({
    required NavigationLocation point,
    required NavigationLocation start,
    required NavigationLocation end,
  }) {
    final referenceLatitude = _toRadians(
      (start.latitude + end.latitude) / 2,
    );

    final scaleX =
        _earthRadius * math.cos(referenceLatitude);

    const scaleY = _earthRadius;

    final bx = _toRadians(
          end.longitude - start.longitude,
        ) *
        scaleX;

    final by = _toRadians(
          end.latitude - start.latitude,
        ) *
        scaleY;

    final px = _toRadians(
          point.longitude - start.longitude,
        ) *
        scaleX;

    final py = _toRadians(
          point.latitude - start.latitude,
        ) *
        scaleY;

    final segmentLengthSquared =
        bx * bx + by * by;

    if (segmentLengthSquared == 0) {
      return start;
    }

    final t = ((px * bx + py * by) /
            segmentLengthSquared)
        .clamp(0.0, 1.0)
        .toDouble();

    return NavigationLocation(
      latitude: start.latitude +
          t * (end.latitude - start.latitude),
      longitude: start.longitude +
          t * (end.longitude - start.longitude),
    );
  }

  NavigationProgress calculateProgress({
    required NavigationLocation currentLocation,
    required List<NavigationLocation> routePoints,
  }) {
    if (routePoints.length < 2) {
      throw ArgumentError(
        'Tuyến đường phải có ít nhất hai điểm.',
      );
    }

    double minimumDistance = double.infinity;

    double accumulatedDistance = 0;

    double traveledDistance = 0;

    int nearestSegmentIndex = 0;

    NavigationLocation snappedLocation =
        routePoints.first;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];

      final projectedPoint = _projectPointToSegment(
        point: currentLocation,
        start: start,
        end: end,
      );

      final distance = distanceService.distanceBetween(
        currentLocation,
        projectedPoint,
      );

      if (distance < minimumDistance) {
        minimumDistance = distance;

        nearestSegmentIndex = i;

        snappedLocation = projectedPoint;

        traveledDistance = accumulatedDistance +
            distanceService.distanceBetween(
              start,
              projectedPoint,
            );
      }

      accumulatedDistance +=
          distanceService.distanceBetween(
        start,
        end,
      );
    }

    final remainingDistance = math.max(
      0.0,
      accumulatedDistance - traveledDistance,
    );

    return NavigationProgress(
      snappedLocation: snappedLocation,
      segmentIndex: nearestSegmentIndex,
      traveledDistance: traveledDistance,
      remainingDistance: remainingDistance,
      distanceFromRoute: minimumDistance,
    );
  }
}