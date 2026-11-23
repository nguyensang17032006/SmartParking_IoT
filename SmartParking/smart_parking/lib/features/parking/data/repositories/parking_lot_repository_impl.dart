import '../../domain/entities/parking_lot.dart';
import '../../domain/repositories/parking_lot_repository.dart';
import '../datasources/parking_lot_remote_data_source.dart';

class ParkingLotRepositoryImpl implements ParkingLotRepository {
  final ParkingLotRemoteDataSource remoteDataSource;

  ParkingLotRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ParkingLot>> getParkingLots(String campusId) async {
    final models = await remoteDataSource.getParkingLots(campusId);

    return models.map<ParkingLot>((model) => model).toList();
  }
}