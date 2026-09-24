import '../../domain/entities/parking_slot.dart';
import '../../domain/repository/parking_repository.dart';
import '../datasource/parking_remote_datasource.dart';

class ParkingRepositoryImpl implements ParkingRepository {
  final ParkingRemoteDataSource remoteDataSource;

  ParkingRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<ParkingSlot>> watchParkingSlots() {
    return remoteDataSource.watchParkingSlots();
  }
}
