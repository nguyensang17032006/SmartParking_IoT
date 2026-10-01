import 'package:equatable/equatable.dart';

enum SlotStatus { free, occupied, reserved, unknown }

class ParkingSlot extends Equatable {
  final String id;
  final String code;
  final bool? occupied;
  final DateTime? lastSeenAt;
  final DateTime? reservedUntil;
  final double mapX;
  final double mapY;

  const ParkingSlot({
    required this.id,
    required this.code,
    required this.occupied,
    this.lastSeenAt,
    this.reservedUntil,
    this.mapX = 0.5,
    this.mapY = 0.5,
  });

  SlotStatus statusAt(DateTime now) {
    if (occupied == null ||
        lastSeenAt == null ||
        now.difference(lastSeenAt!).inSeconds >= 30) {
      return SlotStatus.unknown;
    }
    if (occupied!) return SlotStatus.occupied;
    if (reservedUntil != null && reservedUntil!.isAfter(now)) {
      return SlotStatus.reserved;
    }
    return SlotStatus.free;
  }

  @override
  List<Object?> get props => [
    id,
    code,
    occupied,
    lastSeenAt,
    reservedUntil,
    mapX,
    mapY,
  ];
}
