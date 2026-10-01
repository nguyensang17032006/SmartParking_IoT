import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/core/theme/app_theme.dart';
import 'package:smart_parking/features/parking/domain/entities/parking_slot.dart';
import 'package:smart_parking/features/parking/domain/entities/parking_details.dart';
import 'package:smart_parking/features/parking/domain/repository/parking_repository.dart';
import 'package:smart_parking/features/parking/domain/usecases/indoor_route.dart';
import 'package:smart_parking/features/parking/presentation/pages/parking_page.dart';

class FakeParkingRepository implements ParkingRepository {
  final updates = StreamController<List<ParkingSlot>>.broadcast();
  final reservations = <String>[];
  @override
  Stream<List<ParkingSlot>> watchParkingSlots() => updates.stream;
  @override
  Future<MyParking> getMyParking() async => const MyParking();
  @override
  Future<void> reserve(String code, int minutes) async {
    reservations.add(code);
  }

  @override
  Future<void> cancel(String id) async {}
  @override
  Future<void> confirmParked(String code) async {}
  @override
  Future<void> savePosition(String code, String note) async {}
  @override
  Future<ParkingReport> getReport() async =>
      const ParkingReport(null, 0, null, []);
}

void main() {
  test('unseen and stale slots are unknown; expired hold becomes free', () {
    final now = DateTime.utc(2026, 10, 1);
    const unseen = ParkingSlot(id: '1', code: 'A01', occupied: null);
    expect(unseen.statusAt(now), SlotStatus.unknown);
    final stale = ParkingSlot(
      id: '1',
      code: 'A01',
      occupied: false,
      lastSeenAt: now.subtract(const Duration(seconds: 30)),
    );
    expect(stale.statusAt(now), SlotStatus.unknown);
    final expired = ParkingSlot(
      id: '1',
      code: 'A01',
      occupied: false,
      lastSeenAt: now,
      reservedUntil: now.subtract(const Duration(seconds: 1)),
    );
    expect(expired.statusAt(now), SlotStatus.free);
  });

  test('Dijkstra uses connected lanes and rejects unreachable destination', () {
    const nodes = {
      'gate': MapPoint('gate', 0, 0),
      'aisle': MapPoint('aisle', 0.5, 0),
      'slot': MapPoint('slot', 1, 0),
      'isolated': MapPoint('isolated', 1, 1),
    };
    const edges = {
      'gate': ['aisle'],
      'aisle': ['slot'],
    };
    expect(
      shortestRoute(nodes, edges, 'gate', 'slot').map((p) => p.id).toList(),
      ['gate', 'aisle', 'slot'],
    );
    expect(shortestRoute(nodes, edges, 'gate', 'isolated'), isEmpty);
  });

  testWidgets(
    'stream updates occupied state; unknown slot has no reservation button',
    (tester) async {
      final repository = FakeParkingRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: ParkingPage(repository: repository, onSignOut: () async {}),
        ),
      );
      await tester.pump();
      repository.updates.add([
        ParkingSlot(
          id: '1',
          code: 'A01',
          occupied: false,
          lastSeenAt: DateTime.now().toUtc(),
          mapX: .2,
          mapY: .25,
        ),
      ]);
      await tester.pump();
      expect(find.text('Trống'), findsWidgets);
      repository.updates.add([
        ParkingSlot(
          id: '1',
          code: 'A01',
          occupied: true,
          lastSeenAt: DateTime.now().toUtc(),
          mapX: .2,
          mapY: .25,
        ),
      ]);
      await tester.pump();
      expect(find.text('Có xe'), findsWidgets);
      repository.updates.add([
        const ParkingSlot(
          id: '1',
          code: 'A01',
          occupied: null,
          mapX: .2,
          mapY: .25,
        ),
      ]);
      await tester.pump();
      await tester.tap(find.text('A01').first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Đặt chỗ'), findsNothing);
      expect(find.text('Mất kết nối'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await repository.updates.close();
    },
  );
}
