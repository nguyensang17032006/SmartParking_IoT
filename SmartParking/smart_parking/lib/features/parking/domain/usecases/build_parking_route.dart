import '../entities/parking_map_layout.dart';
import '../entities/parking_route.dart';

/// Only an unoccupied bay with a known physical location can be a target.
class BuildParkingRoute {
  const BuildParkingRoute();

  ParkingRoute? call({
    required ParkingMapLayout layout,
    required String slotCode,
    required bool occupied,
  }) {
    if (occupied) return null;
    final location = layout.locationOf(slotCode);
    if (location == null) return null;
    return ParkingRoute(slotCode: slotCode, destination: location);
  }
}
