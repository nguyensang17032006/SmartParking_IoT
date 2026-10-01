import 'package:equatable/equatable.dart';

import '../../domain/entities/parking_slot.dart';

abstract class ParkingState extends Equatable {
  const ParkingState();

  @override
  List<Object?> get props => [];
}

class ParkingInitial extends ParkingState {}

class ParkingLoading extends ParkingState {}

class ParkingLoaded extends ParkingState {
  final List<ParkingSlot> slots;

  const ParkingLoaded(this.slots);

  @override
  List<Object?> get props => [slots];
}

class ParkingError extends ParkingState {
  final String message;

  const ParkingError(this.message);

  @override
  List<Object?> get props => [message];
}
