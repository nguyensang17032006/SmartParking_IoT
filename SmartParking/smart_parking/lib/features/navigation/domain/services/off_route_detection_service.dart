import 'dart:math' as math;

import '../entities/navigation_location.dart';
import '../entities/navigation_progress.dart';
import '../entities/off_route_result.dart';

class OffRouteDetectionService {
  final double minimumThreshold;

  final double maximumAccuracy;

  final double accuracyMultiplier;

  final int requiredConsecutiveCount;

  const OffRouteDetectionService({
    this.minimumThreshold = 25,
    this.maximumAccuracy = 30,
    this.accuracyMultiplier = 1.5,
    this.requiredConsecutiveCount = 3,
  });

  OffRouteResult evaluate({
    required NavigationLocation location,
    required NavigationProgress progress,
    required int previousCount,
  }) {
    final accuracy = location.accuracy;

    // Sử dụng khoảng cách ngắn nhất đến tuyến.
    final distance = progress.nearestRouteDistance;

    // 1. Kiểm tra chất lượng GPS.
    if (!accuracy.isFinite ||
        accuracy <= 0 ||
        accuracy > maximumAccuracy ||
        !distance.isFinite ||
        distance < 0) {
      return OffRouteResult(
        status: OffRouteStatus.poorAccuracy,
        distanceFromRoute: distance,
        threshold: minimumThreshold,
        consecutiveCount: 0,
      );
    }

    // 2. Tính ngưỡng lệch tuyến động.
    final threshold = math.max(
      minimumThreshold,
      accuracy * accuracyMultiplier,
    );

    // 3. Người dùng vẫn nằm gần tuyến.
    if (distance <= threshold) {
      return OffRouteResult(
        status: OffRouteStatus.onRoute,
        distanceFromRoute: distance,
        threshold: threshold,
        consecutiveCount: 0,
      );
    }

    // 4. Xác nhận lệch tuyến liên tiếp.
    final consecutiveCount = previousCount + 1;

    final status =
        consecutiveCount >= requiredConsecutiveCount
            ? OffRouteStatus.offRoute
            : OffRouteStatus.suspected;

    return OffRouteResult(
      status: status,
      distanceFromRoute: distance,
      threshold: threshold,
      consecutiveCount: consecutiveCount,
    );
  }
}