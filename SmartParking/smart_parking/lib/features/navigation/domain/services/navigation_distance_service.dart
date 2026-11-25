import 'dart:math' as math;

import '../entities/navigation_location.dart';

class NavigationDistanceService {
  const NavigationDistanceService();

  static const double _earthRadius = 6371000;

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double distanceBetween(
    NavigationLocation from,
    NavigationLocation to,
  ) {
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);

    final deltaLat = _toRadians(
      to.latitude - from.latitude,
    );

    final deltaLng = _toRadians(
      to.longitude - from.longitude,
    );

    final a =
        math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(deltaLng / 2), 2);

    final safeA = a.clamp(0.0, 1.0).toDouble();

    final c = 2 *
        math.atan2(
          math.sqrt(safeA),
          math.sqrt(1 - safeA),
        );

    return _earthRadius * c;
  }

  double calculatePathDistance(
    List<NavigationLocation> points,
  ) {
    if (points.length < 2) {
      return 0;
    }

    double totalDistance = 0;

    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += distanceBetween(
        points[i],
        points[i + 1],
      );
    }

    return totalDistance;
  }
}