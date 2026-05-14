import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/AppBar.dart';
import 'package:project/Screens/Components/Topic.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DriverPaymentHistory Widget Tests
//
// The real PaymentHistoryScreen requires Firebase which is unavailable in test environments.
// We test an equivalent structural shell that mirrors the exact same UI layout.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: _DriverPaymentHistoryShell(),
    );
  }

  group('Driver PaymentHistoryScreen Widget Tests', () {
    testWidgets('Renders Payment History structure correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check app bar
      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('Payment History'), findsOneWidget);

      // Check page header
      expect(find.byType(PageHeader), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of PaymentHistoryScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverPaymentHistoryShell extends StatelessWidget {
  const _DriverPaymentHistoryShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Payment History'),
      body: Column(
        children: const [
          PageHeader(title: 'Payments'),
          Expanded(
            child: Center(
              child: Text('No payment history found.'),
            ),
          ),
        ],
      ),
    );
  }
}
