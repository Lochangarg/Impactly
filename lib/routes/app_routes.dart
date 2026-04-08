import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../core/navigation/main_screen.dart';
import '../features/auth/reset_password_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String main = '/main';
  static const String resetPassword = '/reset-password';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    main: (context) => const MainScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),
  };
}
