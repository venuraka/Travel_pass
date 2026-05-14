import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Driver/DriverPendingApproval.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: DriverPendingApprovalScreen(),
    );
  }

  group('Driver PendingApprovalScreen Widget Tests', () {
    testWidgets('Renders all static UI elements correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify Icon
      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsOneWidget);

      // Verify texts
      expect(find.text('Verification Pending'), findsOneWidget);
      expect(
        find.text('Your account is awaiting administrator approval. We are currently verifying your bank details and documents. You will be notified once you can access the dashboard.'),
        findsOneWidget,
      );

      // Verify Buttons
      expect(find.text('Refresh Status'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
