import '../../domain/entities/parking_lot.dart';

class ParkingLotModel extends ParkingLot {
  const ParkingLotModel({
    required super.id,
    required super.campusId,
    required super.name,
    required super.status,
  });

  factory ParkingLotModel.fromJson(Map<String, dynamic> json) {
    return ParkingLotModel(
      id: json['id'] as String,
      campusId: json['campus_id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
    );
  }
}