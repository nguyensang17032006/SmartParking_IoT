import 'package:equatable/equatable.dart';

class ParkingSlot extends Equatable {
  final String id;
  final String code;
  final bool occupied;

  const ParkingSlot({
    required this.id,
    required this.code,
    required this.occupied,
  });

  @override
  List<Object?> get props => [id, code, occupied];
}
