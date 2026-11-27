import '../entities/arrival_result.dart';
import '../entities/navigation_location.dart';

class ArrivalDetectionService {
  final double arrivalRadius;

  final double maximumAccuracy;

  final double maximumRemainingDistance;

  final double maximumDistanceFromRoute;

  final int requiredConsecutiveCount;

  const ArrivalDetectionService({
    this.arrivalRadius = 20,
    this.maximumAccuracy = 15,
    this.maximumRemainingDistance = 30,
    this.maximumDistanceFromRoute = 15,
    this.requiredConsecutiveCount = 3,
  });

  ArrivalResult evaluate({
    required NavigationLocation location,
    required double distanceToDestination,
    required double remainingDistance,
    required double distanceFromRoute,
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

    // 2. Kiểm tra dữ liệu khoảng cách.
    if (!distanceToDestination.isFinite ||
        !remainingDistance.isFinite ||
        !distanceFromRoute.isFinite ||
        distanceToDestination < 0 ||
        remainingDistance < 0 ||
        distanceFromRoute < 0 ||
        distanceToDestination > arrivalRadius ||
        remainingDistance > maximumRemainingDistance ||
        distanceFromRoute > maximumDistanceFromRoute) {
      return ArrivalResult(
        status: ArrivalStatus.approaching,
        distanceToDestination: distanceToDestination,
        consecutiveCount: 0,
      );
    }

    // 3. Xác nhận liên tiếp.
    final consecutiveCount = previousCount + 1;

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