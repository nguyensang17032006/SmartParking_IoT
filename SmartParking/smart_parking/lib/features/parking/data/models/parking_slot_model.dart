
import '../../domain/entities/parking_slot.dart';

class ParkingSlotModel extends ParkingSlot {
  const ParkingSlotModel({
    required super.id,
    required super.zoneId,
    required super.code,
    required super.vehicleType,
    required super.status,
    required super.isActive,
    super.updatedAt,
  });

  factory ParkingSlotModel.fromJson(Map<String, dynamic> json) {
    return ParkingSlotModel(
      id: json['id'] as String,
      zoneId: json['zone_id'] as String,
      code: json['code'] as String,
      vehicleType: json['vehicle_type'] as String,
      status: json['status'] as String,
      isActive: json['is_active'] as bool,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }
}
