import '../entities/map_element.dart';
import '../entities/map_version.dart';

abstract class ParkingMapRepository {
  Future<List<MapElement>> getMapElements(
    String mapVersionId,
    String floorId,
  );

  Future<MapVersion?> getPublishedMapVersion(String campusId);
}