import '../../domain/entities/parking_slot.dart';

class ParkingSlotModel extends ParkingSlot {
  const ParkingSlotModel({
    required super.id,
    required super.code,
    required super.occupied,
    super.lastSeenAt,
    super.reservedUntil,
    super.mapX,
    super.mapY,
  });

  factory ParkingSlotModel.fromJson(Map<String, dynamic> json) {
    return ParkingSlotModel(
      id: json['id'].toString(),
      code: json['code'] as String,
      occupied: json['sensor_occupied'] as bool?,
      lastSeenAt: DateTime.tryParse(json['last_seen_at']?.toString() ?? '')
          ?.toUtc(),
      reservedUntil: DateTime.tryParse(json['reserved_until']?.toString() ?? '')
          ?.toUtc(),
      mapX: (json['map_x'] as num?)?.toDouble() ?? 0.5,
      mapY: (json['map_y'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
