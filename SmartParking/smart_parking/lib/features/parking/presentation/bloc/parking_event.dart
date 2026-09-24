import 'package:equatable/equatable.dart';

abstract class ParkingEvent extends Equatable {
  const ParkingEvent();

  @override
  List<Object?> get props => [];
}

class ParkingWatchStarted extends ParkingEvent {
  const ParkingWatchStarted();
}
