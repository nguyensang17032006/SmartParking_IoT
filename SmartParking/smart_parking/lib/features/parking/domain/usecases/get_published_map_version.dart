import '../entities/map_version.dart';
import '../repositories/parking_map_repository.dart';

class GetPublishedMapVersion {
  final ParkingMapRepository repository;

  GetPublishedMapVersion(this.repository);

  Future<MapVersion?> call(String campusId) {
    return repository.getPublishedMapVersion(campusId);
  }
}