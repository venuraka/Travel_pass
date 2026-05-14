import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/passenger/PendingApproval.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: PendingApprovalScreen(),
    );
  }

  group('Passenger PendingApprovalScreen Widget Tests', () {
    testWidgets('Renders all static UI elements correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify Icon
      expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);

      // Verify texts
      expect(find.text('Registration Pending'), findsOneWidget);
      expect(
        find.text('Your registration is awaiting driver approval. You will be able to access the app once your driver approves your request.'),
        findsOneWidget,
      );

      // Verify Buttons
      expect(find.text('Check Status'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
