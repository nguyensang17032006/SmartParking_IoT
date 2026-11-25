enum ArrivalStatus {
  approaching,
  suspected,
  arrived,
  poorAccuracy,
}

class ArrivalResult {
  final ArrivalStatus status;

  final double distanceToDestination;

  final int consecutiveCount;

  const ArrivalResult({
    required this.status,
    required this.distanceToDestination,
    required this.consecutiveCount,
  });

  bool get isArrived =>
      status == ArrivalStatus.arrived;
}