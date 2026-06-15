import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const DriveGuardApp());
}

class DriveGuardApp extends StatelessWidget {
  const DriveGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveGuard AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
