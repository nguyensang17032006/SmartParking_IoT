import '../entities/navigation_location.dart';
import 'navigation_distance_service.dart';

class RouteGeometryService {
  final NavigationDistanceService distanceService;

  const RouteGeometryService({
    this.distanceService =
        const NavigationDistanceService(),
  });

  // Tính khoảng cách tích lũy tại từng điểm.
  List<double> buildCumulativeDistances(
    List<NavigationLocation> points,
  ) {
    if (points.isEmpty) return [];

    final distances = <double>[0.0];

    for (int i = 1; i < points.length; i++) {
      final distance = distanceService.distanceBetween(
        points[i - 1],
        points[i],
      );

      distances.add(
        distances.last + distance,
      );
    }

    return distances;
  }

  // Tìm đoạn đường bằng Binary Search.
  int findSegmentIndex({
    required List<double> cumulativeDistances,
    required double traveledDistance,
  }) {
    if (cumulativeDistances.length < 2) {
      return 0;
    }

    int low = 0;
    int high = cumulativeDistances.length - 1;

    while (low < high) {
      final mid = (low + high + 1) ~/ 2;

      if (cumulativeDistances[mid] <=
          traveledDistance) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }

    return low
        .clamp(0, cumulativeDistances.length - 2)
        .toInt();
  }

  // Chuyển khoảng cách đã đi thành tọa độ.
  NavigationLocation positionAtDistance({
    required List<NavigationLocation> points,
    required List<double> cumulativeDistances,
    required double traveledDistance,
  }) {
    if (points.isEmpty) {
      throw ArgumentError(
        'Tuyến đường không có tọa độ.',
      );
    }

    if (points.length == 1) {
      return points.first;
    }

    final distance = traveledDistance
        .clamp(0.0, cumulativeDistances.last)
        .toDouble();

    final index = findSegmentIndex(
      cumulativeDistances: cumulativeDistances,
      traveledDistance: distance,
    );

    final start = points[index];
    final end = points[index + 1];

    final segmentLength =
        cumulativeDistances[index + 1] -
        cumulativeDistances[index];

    final fraction = segmentLength > 0
        ? ((distance - cumulativeDistances[index]) /
                segmentLength)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;

    return NavigationLocation(
      latitude: start.latitude +
          (end.latitude - start.latitude) *
              fraction,
      longitude: start.longitude +
          (end.longitude - start.longitude) *
              fraction,
    );
  }

  // Lấy phần tuyến đường chưa đi qua.
  List<NavigationLocation> remainingRoute({
    required List<NavigationLocation> points,
    required List<double> cumulativeDistances,
    required double traveledDistance,
  }) {
    if (points.length < 2) {
      return points;
    }

    if (traveledDistance >=
        cumulativeDistances.last) {
      return [];
    }

    final index = findSegmentIndex(
      cumulativeDistances: cumulativeDistances,
      traveledDistance: traveledDistance,
    );

    final currentPosition = positionAtDistance(
      points: points,
      cumulativeDistances: cumulativeDistances,
      traveledDistance: traveledDistance,
    );

    return [
      currentPosition,
      ...points.skip(index + 1),
    ];
  }
}