import '../entities/parking_slot.dart';
import '../entities/parking_details.dart';

abstract class ParkingRepository {
  Stream<List<ParkingSlot>> watchParkingSlots();
  Future<MyParking> getMyParking();
  Future<void> reserve(String code, int minutes);
  Future<void> cancel(String id);
  Future<void> confirmParked(String code);
  Future<void> savePosition(String code, String note);
  Future<ParkingReport> getReport();
}
