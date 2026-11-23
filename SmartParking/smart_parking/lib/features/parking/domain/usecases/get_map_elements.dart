import '../entities/map_element.dart';
import '../repositories/parking_map_repository.dart';

class GetMapElements {
  final ParkingMapRepository repository;

  GetMapElements(this.repository);

  Future<List<MapElement>> call(
    String mapVersionId,
    String floorId,
  ) {
    return repository.getMapElements(mapVersionId, floorId);
  }
}