import '../entities/parking_slot.dart';

abstract class ParkingRepository {
  Stream<List<ParkingSlot>> watchParkingSlots();
}
