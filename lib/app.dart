import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_shell.dart';
import 'screens/login/login_screen.dart';
import 'services/auth_service.dart';
import 'models/models.dart';

class AppPichincha extends StatelessWidget {
  const AppPichincha({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banco Pichincha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StreamBuilder<Usuario?>(
        stream: AuthService.onAuthStateChanged,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
