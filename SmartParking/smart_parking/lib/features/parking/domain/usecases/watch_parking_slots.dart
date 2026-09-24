import '../entities/parking_slot.dart';
import '../repository/parking_repository.dart';

class WatchParkingSlots {
  final ParkingRepository repository;

  WatchParkingSlots(this.repository);

  Stream<List<ParkingSlot>> call() {
    return repository.watchParkingSlots();
  }
}
