enum OffRouteStatus {
  onRoute,
  suspected,
  offRoute,
  poorAccuracy,
}

class OffRouteResult {
  final OffRouteStatus status;

  final double distanceFromRoute;

  final double threshold;

  final int consecutiveCount;

  const OffRouteResult({
    required this.status,
    required this.distanceFromRoute,
    required this.threshold,
    required this.consecutiveCount,
  });

  bool get isOffRoute =>
      status == OffRouteStatus.offRoute;
}