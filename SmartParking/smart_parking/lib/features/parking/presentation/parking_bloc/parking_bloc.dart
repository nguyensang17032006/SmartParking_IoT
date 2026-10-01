import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/watch_parking_slots.dart';
import 'parking_event.dart';
import 'parking_state.dart';

class ParkingBloc extends Bloc<ParkingEvent, ParkingState> {
  final WatchParkingSlots watchParkingSlots;

  ParkingBloc({required this.watchParkingSlots}) : super(ParkingInitial()) {
    on<ParkingWatchStarted>(_onWatchStarted);
  }

  Future<void> _onWatchStarted(
    ParkingWatchStarted event,
    Emitter<ParkingState> emit,
  ) async {
    emit(ParkingLoading());

    await emit.forEach(
      watchParkingSlots(),

      onData: (slots) {
        debugPrint(
          'BLOC: ${slots.map((e) => '${e.code}:${e.occupied}').toList()}',
        );
        return ParkingLoaded(slots);
      },

      onError: (error, stackTrace) {
        debugPrint('BLOC ERROR: $error');
        return ParkingError(error.toString());
      },
    );
  }
}
