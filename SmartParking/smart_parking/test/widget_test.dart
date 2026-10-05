import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/core/app/main_layout.dart';
import 'package:smart_parking/features/parking/domain/entities/parking_slot.dart';
import 'package:smart_parking/features/parking/domain/repository/parking_repository.dart';
import 'package:smart_parking/features/parking/domain/usecases/watch_parking_slots.dart';
import 'package:smart_parking/main.dart';

const _slots = [
  ParkingSlot(id: '1', code: 'A01', occupied: false),
  ParkingSlot(id: '2', code: 'A02', occupied: true),
  ParkingSlot(id: '3', code: 'A03', occupied: false),
  ParkingSlot(id: '4', code: 'B01', occupied: true),
  ParkingSlot(id: '5', code: 'B02', occupied: false),
  ParkingSlot(id: '6', code: 'B03', occupied: true),
];

class _FakeRepository implements ParkingRepository {
  int watchCount = 0;
  @override
  Stream<List<ParkingSlot>> watchParkingSlots() {
    watchCount++;
    return Stream.value(_slots);
  }
}

Future<_FakeRepository> _openHome(WidgetTester tester) async {
  final repository = _FakeRepository();
  await tester.pumpWidget(
    MyApp(
      watchParkingSlots: WatchParkingSlots(repository),
      initialRoute: '/home',
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('Home uses sensor totals and handles a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _openHome(tester);
    expect(find.text('3 chỗ còn trống'), findsOneWidget);
    expect(find.text('3/6 ô đang có xe'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home and map navigation preserve route and search', (
    tester,
  ) async {
    final repository = await _openHome(tester);
    await tester.tap(find.text('Sơ đồ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'A01');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('A01'));
    await tester.tap(find.text('A01'));
    await tester.pumpAndSettle();
    expect(find.text('Cổng vào → A01'), findsOneWidget);

    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sơ đồ'));
    await tester.pumpAndSettle();
    expect(find.text('Cổng vào → A01'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'A01',
    );
    expect(repository.watchCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Named home route can access the root ParkingBloc', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MyApp(watchParkingSlots: WatchParkingSlots(repository)),
    );
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Đăng nhập tài khoản')))
        .pushNamedAndRemoveUntil('/home', (_) => false);
    await tester.pumpAndSettle();
    expect(find.byType(MainLayout), findsOneWidget);
    expect(find.text('3 chỗ còn trống'), findsOneWidget);
    expect(repository.watchCount, 1);
    expect(tester.takeException(), isNull);
  });
}
