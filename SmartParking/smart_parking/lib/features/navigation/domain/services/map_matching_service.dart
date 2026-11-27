import 'dart:math' as math;

import '../entities/map_matching_result.dart';
import '../entities/navigation_location.dart';
import '../entities/navigation_progress.dart';
import 'navigation_distance_service.dart';

class MapMatchingService {
  final NavigationDistanceService distanceService;

  const MapMatchingService({
    this.distanceService =
        const NavigationDistanceService(),
  });

  static const double _earthRadius = 6371000;

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double _toDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  // Tính hướng của một đoạn đường.
  double _calculateBearing(
    NavigationLocation start,
    NavigationLocation end,
  ) {
    final lat1 = _toRadians(start.latitude);
    final lat2 = _toRadians(end.latitude);

    final deltaLng = _toRadians(
      end.longitude - start.longitude,
    );

    final y =
        math.sin(deltaLng) * math.cos(lat2);

    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) *
            math.cos(lat2) *
            math.cos(deltaLng);

    return (_toDegrees(math.atan2(y, x)) + 360) %
        360;
  }

  // Tính độ chênh lệch giữa hai hướng.
  double _headingDifference(
    double first,
    double second,
  ) {
    final difference = (first - second).abs() % 360;

    return math.min(
      difference,
      360 - difference,
    );
  }

  MapMatchingResult match({
    required NavigationLocation currentLocation,
    required List<NavigationLocation> routePoints,
    NavigationProgress? previousProgress,
  }) {
    if (routePoints.length < 2) {
      throw ArgumentError(
        'Tuyến đường phải có ít nhất 2 điểm.',
      );
    }

    MapMatchingResult? bestMatch;

    double cumulativeDistance = 0;

    // Khoảng cách ngắn nhất từ GPS đến toàn tuyến.
    double nearestRouteDistance = double.infinity;

    final referenceLatitude = _toRadians(
      currentLocation.latitude,
    );

    final longitudeScale =
        math.cos(referenceLatitude);

    final hasReliableHeading =
        currentLocation.speed.isFinite &&
        currentLocation.speed >= 2 &&
        currentLocation.heading.isFinite &&
        currentLocation.heading >= 0 &&
        currentLocation.heading <= 360;

    final accuracy =
        currentLocation.accuracy.isFinite &&
            currentLocation.accuracy > 0
        ? currentLocation.accuracy
        : 20.0;

    for (int i = 0;
        i < routePoints.length - 1;
        i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];

      final segmentDistance =
          distanceService.distanceBetween(
        start,
        end,
      );

      if (segmentDistance <= 0) {
        continue;
      }

      // Chuyển tọa độ sang hệ tọa độ mét cục bộ.
      final ax = _toRadians(
            start.longitude -
                currentLocation.longitude,
          ) *
          _earthRadius *
          longitudeScale;

      final ay = _toRadians(
            start.latitude -
                currentLocation.latitude,
          ) *
          _earthRadius;

      final bx = _toRadians(
            end.longitude -
                currentLocation.longitude,
          ) *
          _earthRadius *
          longitudeScale;

      final by = _toRadians(
            end.latitude -
                currentLocation.latitude,
          ) *
          _earthRadius;

      final dx = bx - ax;
      final dy = by - ay;

      final lengthSquared = dx * dx + dy * dy;

      if (lengthSquared <= 0) {
        cumulativeDistance += segmentDistance;
        continue;
      }

      // Chiếu GPS lên đoạn đường.
      final fraction =
          (-(ax * dx + ay * dy) / lengthSquared)
              .clamp(0.0, 1.0)
              .toDouble();

      final snappedLocation = NavigationLocation(
        latitude: start.latitude +
            (end.latitude - start.latitude) *
                fraction,
        longitude: start.longitude +
            (end.longitude - start.longitude) *
                fraction,
      );

      final distanceFromRoute =
          distanceService.distanceBetween(
        currentLocation,
        snappedLocation,
      );

      // Cập nhật khoảng cách ngắn nhất đến tuyến.
      nearestRouteDistance = math.min(
        nearestRouteDistance,
        distanceFromRoute,
      );

      final traveledDistance =
          cumulativeDistance +
          segmentDistance * fraction;

      // Điểm cơ bản: càng gần đường càng tốt.
      double score = distanceFromRoute;

      // Phạt nếu hướng di chuyển không phù hợp.
      if (hasReliableHeading) {
        final segmentBearing = _calculateBearing(
          start,
          end,
        );

        final headingDifference =
            _headingDifference(
          currentLocation.heading,
          segmentBearing,
        );

        score +=
            (headingDifference / 180) * 20;
      }

      // Ưu tiên tiến độ liên tục.
      if (previousProgress != null) {
        final progressDifference =
            traveledDistance -
                previousProgress.traveledDistance;

        final backwardTolerance =
            math.max(10.0, accuracy);

        if (progressDifference <
            -backwardTolerance) {
          score +=
              (-progressDifference -
                      backwardTolerance) *
                  0.8;
        }

        final forwardTolerance = math.max(
          60.0,
          accuracy * 3,
        );

        if (progressDifference >
            forwardTolerance) {
          score +=
              (progressDifference -
                      forwardTolerance) *
                  0.5;
        }
      }

      final candidate = MapMatchingResult(
        snappedLocation: snappedLocation,
        segmentIndex: i,
        segmentFraction: fraction,
        distanceFromRoute: distanceFromRoute,
        nearestRouteDistance: nearestRouteDistance,
        traveledDistance: traveledDistance,
        score: score,
      );

      if (bestMatch == null ||
          candidate.score < bestMatch.score) {
        bestMatch = candidate;
      }

      cumulativeDistance += segmentDistance;
    }

    if (bestMatch == null) {
      throw StateError(
        'Không tìm được đoạn đường hợp lệ.',
      );
    }

    // Trả về đoạn đường phù hợp nhất cùng khoảng
    // cách ngắn nhất sau khi duyệt toàn bộ tuyến.
    return MapMatchingResult(
      snappedLocation: bestMatch.snappedLocation,
      segmentIndex: bestMatch.segmentIndex,
      segmentFraction: bestMatch.segmentFraction,
      distanceFromRoute: bestMatch.distanceFromRoute,
      nearestRouteDistance: nearestRouteDistance,
      traveledDistance: bestMatch.traveledDistance,
      score: bestMatch.score,
    );
  }
}