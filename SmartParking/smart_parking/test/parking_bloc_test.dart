import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/features/parking/domain/entities/parking_slot.dart';
import 'package:smart_parking/features/parking/domain/repository/parking_repository.dart';
import 'package:smart_parking/features/parking/domain/usecases/watch_parking_slots.dart';
import 'package:smart_parking/features/parking/presentation/parking_bloc/parking_bloc.dart';
import 'package:smart_parking/features/parking/presentation/parking_bloc/parking_event.dart';
import 'package:smart_parking/features/parking/presentation/parking_bloc/parking_state.dart';

const _slots = [
  ParkingSlot(id: '1', code: 'A01', occupied: false),
  ParkingSlot(id: '2', code: 'A02', occupied: true),
];

class _ControlledRepository implements ParkingRepository {
  final controllers = <StreamController<List<ParkingSlot>>>[];
  final subscribed = StreamController<int>.broadcast();
  int cancellations = 0;

  @override
  Stream<List<ParkingSlot>> watchParkingSlots() {
    late StreamController<List<ParkingSlot>> controller;
    controller = StreamController<List<ParkingSlot>>(
      onListen: () => subscribed.add(controllers.indexOf(controller)),
      onCancel: () {
        cancellations++;
      },
    );
    controllers.add(controller);
    return controller.stream;
  }

  Future<void> dispose() async {
    for (final controller in controllers) {
      await controller.close();
    }
    await subscribed.close();
  }
}

void main() {
  test('retry cancels the prior watch and loads the new stream', () async {
    final repository = _ControlledRepository();
    final bloc = ParkingBloc(watchParkingSlots: WatchParkingSlots(repository));
    final firstSubscribed = repository.subscribed.stream.first;
    bloc.add(const ParkingWatchStarted());
    expect(await firstSubscribed, 0);
    final firstLoaded = bloc.stream.firstWhere((s) => s is ParkingLoaded);
    repository.controllers[0].add(_slots);
    await firstLoaded;

    final nextSubscribed = repository.subscribed.stream.first;
    bloc.add(const ParkingWatchStarted());
    expect(await nextSubscribed, 1);
    expect(repository.cancellations, 1);
    final nextLoaded = bloc.stream.firstWhere((s) => s is ParkingLoaded);
    repository.controllers[1].add([
      const ParkingSlot(id: '1', code: 'A01', occupied: true),
    ]);
    final loaded = await nextLoaded as ParkingLoaded;
    expect(loaded.slots.single.occupied, isTrue);
    await bloc.close();
    expect(repository.cancellations, 2);
    await repository.dispose();
  });

  test('watch error reaches UI and can be retried', () async {
    final repository = _ControlledRepository();
    final bloc = ParkingBloc(watchParkingSlots: WatchParkingSlots(repository));
    final firstSubscribed = repository.subscribed.stream.first;
    bloc.add(const ParkingWatchStarted());
    await firstSubscribed;
    final error = bloc.stream.firstWhere((s) => s is ParkingError);
    repository.controllers[0].addError(StateError('connection failed'));
    expect(
      (await error as ParkingError).message,
      contains('connection failed'),
    );
    final secondSubscribed = repository.subscribed.stream.first;
    bloc.add(const ParkingWatchStarted());
    await secondSubscribed;
    final loaded = bloc.stream.firstWhere((s) => s is ParkingLoaded);
    repository.controllers[1].add(_slots);
    expect((await loaded as ParkingLoaded).slots, _slots);
    await bloc.close();
    await repository.dispose();
  });

  test('closing Bloc cancels its sensor subscription', () async {
    final repository = _ControlledRepository();
    final bloc = ParkingBloc(watchParkingSlots: WatchParkingSlots(repository));
    final subscribed = repository.subscribed.stream.first;
    bloc.add(const ParkingWatchStarted());
    await subscribed;
    await bloc.close();
    expect(repository.cancellations, 1);
    // A late sensor event must not add events to a closed Bloc.
    repository.controllers[0].add(_slots);
    await repository.dispose();
  });
}
