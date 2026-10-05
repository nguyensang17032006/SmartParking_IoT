/// Occupancy totals, independent of Flutter, Supabase and screen dimensions.
class ParkingOverview {
  final int totalCount;
  final int occupiedCount;

  const ParkingOverview._({
    required this.totalCount,
    required this.occupiedCount,
  });

  factory ParkingOverview.fromOccupancy(Iterable<bool> occupancy) {
    var total = 0;
    var occupied = 0;
    for (final hasCar in occupancy) {
      total++;
      if (hasCar) occupied++;
    }
    return ParkingOverview._(totalCount: total, occupiedCount: occupied);
  }

  int get availableCount => totalCount - occupiedCount;
  double get occupancyRate => totalCount == 0 ? 0 : occupiedCount / totalCount;
  bool get isFull => totalCount > 0 && availableCount == 0;
}
