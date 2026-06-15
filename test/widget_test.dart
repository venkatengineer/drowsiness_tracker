import 'package:driver_assist/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows DriveGuard login screen', (tester) async {
    await tester.pumpWidget(const DriveGuardApp());

    expect(find.text('DriveGuard AI'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
