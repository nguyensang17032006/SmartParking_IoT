
class ParkingSlot {
  final String id;
  final String zoneId;
  final String code;
  final String vehicleType;
  final String status;
  final bool isActive;
  final DateTime? updatedAt;

  const ParkingSlot({
    required this.id,
    required this.zoneId,
    required this.code,
    required this.vehicleType,
    required this.status,
    required this.isActive,
    this.updatedAt,
  });
}
