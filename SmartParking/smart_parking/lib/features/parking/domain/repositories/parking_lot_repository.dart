import '../entities/parking_lot.dart';

abstract class ParkingLotRepository {
  Future<List<ParkingLot>> getParkingLots(String campusId);
}