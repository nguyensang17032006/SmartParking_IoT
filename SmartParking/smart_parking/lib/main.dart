import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/parking/data/datasource/parking_remote_datasource.dart';
import 'features/parking/data/repository/parking_repository_impl.dart';
import 'features/parking/domain/usecases/watch_parking_slots.dart';
import 'features/parking/presentation/bloc/parking_bloc.dart';
import 'features/parking/presentation/bloc/parking_event.dart';
import 'features/parking/presentation/pages/parking_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  debugPrint('Supabase URL loaded: ${dotenv.env['SUPABASE_URL'] != null}');

  debugPrint(
    'Supabase key loaded: ${dotenv.env['SUPABASE_PUBLISHABLE_KEY'] != null}',
  );
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  final supabase = Supabase.instance.client;

  final remoteDataSource = ParkingRemoteDataSourceImpl(supabase: supabase);

  final repository = ParkingRepositoryImpl(remoteDataSource: remoteDataSource);

  final watchParkingSlots = WatchParkingSlots(repository);

  runApp(MyApp(watchParkingSlots: watchParkingSlots));
}

class MyApp extends StatelessWidget {
  final WatchParkingSlots watchParkingSlots;

  const MyApp({super.key, required this.watchParkingSlots});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) =>
            ParkingBloc(watchParkingSlots: watchParkingSlots)
              ..add(const ParkingWatchStarted()),
        child: const ParkingPage(),
      ),
    );
  }
}
