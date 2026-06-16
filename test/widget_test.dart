import 'package:driver_assist/core/theme/app_theme.dart';
import 'package:driver_assist/routes/app_routes.dart';
import 'package:driver_assist/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Driver Assist login screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(),
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
        },
      ),
    );

    expect(find.text('Driver Assist'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
