import '../entities/arrival_result.dart';
import '../entities/navigation_location.dart';

class ArrivalDetectionService {
  final double arrivalRadius;

  final double maximumAccuracy;

  final double maximumRemainingDistance;

  final int requiredConsecutiveCount;

  const ArrivalDetectionService({
    this.arrivalRadius = 20,
    this.maximumAccuracy = 15,
    this.maximumRemainingDistance = 30,
    this.requiredConsecutiveCount = 3,
  });

  ArrivalResult evaluate({
    required NavigationLocation location,
    required double distanceToDestination,
    required double remainingDistance,
    required int previousCount,
  }) {
    final accuracy = location.accuracy;

    // 1. Kiểm tra chất lượng GPS.
    if (!accuracy.isFinite ||
        accuracy <= 0 ||
        accuracy > maximumAccuracy) {
      return ArrivalResult(
        status: ArrivalStatus.poorAccuracy,
        distanceToDestination: distanceToDestination,
        consecutiveCount: 0,
      );
    }

    // 2. Kiểm tra khoảng cách.
    if (!distanceToDestination.isFinite ||
        !remainingDistance.isFinite ||
        distanceToDestination < 0 ||
        remainingDistance < 0 ||
        distanceToDestination > arrivalRadius ||
        remainingDistance > maximumRemainingDistance) {
      return ArrivalResult(
        status: ArrivalStatus.approaching,
        distanceToDestination: distanceToDestination,
        consecutiveCount: 0,
      );
    }

    // 3. Tăng số lần xác nhận.
    final consecutiveCount = previousCount + 1;

    // 4. Xác định trạng thái đến nơi.
    final status =
        consecutiveCount >= requiredConsecutiveCount
            ? ArrivalStatus.arrived
            : ArrivalStatus.suspected;

    return ArrivalResult(
      status: status,
      distanceToDestination: distanceToDestination,
      consecutiveCount: consecutiveCount,
    );
  }
}