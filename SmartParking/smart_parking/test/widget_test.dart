// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_parking/features/parking/data/datasource/parking_remote_datasource.dart';
import 'package:smart_parking/features/parking/data/repository/parking_repository_impl.dart';
import 'package:smart_parking/features/parking/domain/usecases/watch_parking_slots.dart';

import 'package:smart_parking/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
    );

    final supabase = Supabase.instance.client;

    // Data source
    final remoteDataSource = ParkingRemoteDataSourceImpl(supabase: supabase);

    // Repository
    final repository = ParkingRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    // Use case
    final watchParkingSlots = WatchParkingSlots(repository);
    await tester.pumpWidget(MyApp(watchParkingSlots: watchParkingSlots));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
