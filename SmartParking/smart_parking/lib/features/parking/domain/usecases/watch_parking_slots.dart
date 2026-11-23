
import '../entities/parking_slot.dart';
import '../repositories/parking_slot_repository.dart';

class WatchParkingSlots {
  final ParkingSlotRepository repository;

  WatchParkingSlots(this.repository);

  Stream<List<ParkingSlot>> call() {
    return repository.watchParkingSlots();
  }
}
  