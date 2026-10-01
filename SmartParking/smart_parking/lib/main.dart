import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/parking/data/datasource/parking_remote_datasource.dart';
import 'features/parking/data/repository/parking_repository_impl.dart';
import 'features/parking/presentation/pages/parking_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
    if (url.isEmpty || key.isEmpty) {
      throw StateError('Thiếu SUPABASE_URL hoặc SUPABASE_PUBLISHABLE_KEY.');
    }
    await Supabase.initialize(url: url, publishableKey: key);
    runApp(const MyApp());
  } catch (_) {
    runApp(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa kết nối được dịch vụ. Kiểm tra cấu hình Supabase và mở lại ứng dụng.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bãi xe đại học',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = client.auth.currentUser;
        if (user == null) return const LoginPage();
        return ParkingPage(
          key: ValueKey(user.id),
          repository: ParkingRepositoryImpl(
            remoteDataSource: ParkingRemoteDataSourceImpl(supabase: client),
          ),
          onSignOut: () => client.auth.signOut(),
        );
      },
    );
  }
}
