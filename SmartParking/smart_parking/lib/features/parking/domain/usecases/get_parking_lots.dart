import '../entities/parking_lot.dart';
import '../repositories/parking_lot_repository.dart';

class GetParkingLots {
  final ParkingLotRepository repository;

  GetParkingLots(this.repository);

  Future<List<ParkingLot>> call(String campusId) {
    return repository.getParkingLots(campusId);
  }
}