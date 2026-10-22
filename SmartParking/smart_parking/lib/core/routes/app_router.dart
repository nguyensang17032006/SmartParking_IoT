import 'package:flutter/material.dart';
import 'package:smart_parking/core/routes/app_routes.dart';
import 'package:smart_parking/features/auth/presentation/pages/login_page.dart';
import 'package:smart_parking/features/auth/presentation/pages/signup_page.dart';
import 'package:smart_parking/features/auth/presentation/pages/otp_page.dart';
import 'package:smart_parking/features/auth/presentation/pages/recovery_page.dart';
import 'package:smart_parking/features/auth/presentation/pages/recovery_success_page.dart';
import 'package:smart_parking/features/auth/presentation/pages/updatephone_page.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case AppRoutes.signup:
        return MaterialPageRoute(
          builder: (_) => const SignUpPage(),
          settings: settings,
        );
      case AppRoutes.recovery:
        return MaterialPageRoute(
          builder: (_) => const RecoveryPage(),
          settings: settings,
        );

      case AppRoutes.recoverySuccess:
        return MaterialPageRoute(
          builder: (_) => RecoverySuccessPage(),
          settings: settings,
        );
      case AppRoutes.updatePhone:
        final args = settings.arguments as Map<String, dynamic>;
        final recoveryToken = args['recoveryToken'] as String;

        return MaterialPageRoute(
          builder: (_) => UpdatePhonePage(recoveryToken: recoveryToken),
          settings: settings,
        );
      case AppRoutes.otp:
        final args = settings.arguments as Map<String, dynamic>;

        final flow = switch (args['flow']) {
          'signup' => OtpFlow.signup,
          'recoveryEmail' => OtpFlow.recoveryEmail,
          'recoveryPhone' => OtpFlow.recoveryPhone,
          _ => OtpFlow.login,
        };

        final isEmail = flow == OtpFlow.recoveryEmail;

        final destination = isEmail
            ? args['email'] as String?
            : args['phone'] as String?;

        if (destination == null || destination.trim().isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Thiếu email hoặc số điện thoại xác thực'),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => OtpPage(destination: destination, flow: flow),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
    }
  }
}
