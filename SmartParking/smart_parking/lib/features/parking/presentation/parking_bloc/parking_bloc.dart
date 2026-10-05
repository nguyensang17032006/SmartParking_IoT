import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/parking_slot.dart';
import '../../domain/usecases/watch_parking_slots.dart';
import 'parking_event.dart';
import 'parking_state.dart';

class ParkingBloc extends Bloc<ParkingEvent, ParkingState> {
  final WatchParkingSlots watchParkingSlots;
  StreamSubscription<List<ParkingSlot>>? _subscription;
  int _watchGeneration = 0;

  ParkingBloc({required this.watchParkingSlots}) : super(ParkingInitial()) {
    on<ParkingWatchStarted>(_onWatchStarted);
    on<_ParkingSlotsChanged>((event, emit) {
      if (event.generation == _watchGeneration) {
        emit(ParkingLoaded(List.unmodifiable(event.slots)));
      }
    });
    on<_ParkingWatchFailed>((event, emit) {
      if (event.generation == _watchGeneration) {
        emit(ParkingError(event.message));
      }
    });
  }

  Future<void> _onWatchStarted(
    ParkingWatchStarted event,
    Emitter<ParkingState> emit,
  ) async {
    final generation = ++_watchGeneration;
    emit(ParkingLoading());
    await _subscription?.cancel();
    if (isClosed || generation != _watchGeneration) return;

    try {
      _subscription = watchParkingSlots().listen(
        (slots) {
          if (!isClosed && generation == _watchGeneration) {
            add(_ParkingSlotsChanged(generation, slots));
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!isClosed && generation == _watchGeneration) {
            add(_ParkingWatchFailed(generation, error.toString()));
          }
        },
      );
    } catch (error) {
      if (!isClosed && generation == _watchGeneration) {
        emit(ParkingError(error.toString()));
      }
    }
  }

  @override
  Future<void> close() async {
    ++_watchGeneration;
    await _subscription?.cancel();
    return super.close();
  }
}

// Stream callbacks enter Bloc through events, never a completed Emitter.
class _ParkingSlotsChanged extends ParkingEvent {
  final int generation;
  final List<ParkingSlot> slots;
  const _ParkingSlotsChanged(this.generation, this.slots);
}

class _ParkingWatchFailed extends ParkingEvent {
  final int generation;
  final String message;
  const _ParkingWatchFailed(this.generation, this.message);
}
