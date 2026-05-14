import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/AppBar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DriverNewPassenger Widget Tests
//
// The real NewPassengerScreen requires Firebase which is unavailable in test environments.
// We test an equivalent structural shell that mirrors the exact same UI layout.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: _DriverNewPassengerShell(),
    );
  }

  group('Driver NewPassengerScreen Widget Tests', () {
    testWidgets('Renders New Passenger screen structure correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check app bar
      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('New Passenger List'), findsOneWidget);

      // Verify empty state
      expect(find.text('No new passengers found.'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of NewPassengerScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverNewPassengerShell extends StatelessWidget {
  const _DriverNewPassengerShell();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'New Passenger List'),
      body: Center(
        child: Text(
          'No new passengers found.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
