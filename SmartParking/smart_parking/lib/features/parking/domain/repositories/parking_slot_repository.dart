
import '../entities/parking_slot.dart';

abstract class ParkingSlotRepository {
  Stream<List<ParkingSlot>> watchParkingSlots();
}
