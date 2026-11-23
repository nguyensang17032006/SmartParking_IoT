
import '../../domain/entities/parking_slot.dart';
import '../../domain/repositories/parking_slot_repository.dart';
import '../datasources/parking_slot_remote_data_source.dart';

class ParkingSlotRepositoryImpl
    implements ParkingSlotRepository {
  final ParkingSlotRemoteDataSource dataSource;

  ParkingSlotRepositoryImpl(this.dataSource);

  @override
  Stream<List<ParkingSlot>> watchParkingSlots() {
    return dataSource.watchParkingSlots();
  }
}
