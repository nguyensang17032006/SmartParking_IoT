import '../../domain/entities/map_element.dart';
import '../../domain/entities/map_version.dart';
import '../../domain/repositories/parking_map_repository.dart';
import '../datasources/parking_map_remote_data_source.dart';

class ParkingMapRepositoryImpl implements ParkingMapRepository {
  final ParkingMapRemoteDataSource remoteDataSource;

  ParkingMapRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<MapElement>> getMapElements(
    String mapVersionId,
    String floorId,
  ) async {
    final models = await remoteDataSource.getMapElements(
      mapVersionId,
      floorId,
    );

    return models.map<MapElement>((model) => model).toList();
  }

  @override
  Future<MapVersion?> getPublishedMapVersion(String campusId) {
    return remoteDataSource.getPublishedMapVersion(campusId);
  }
}