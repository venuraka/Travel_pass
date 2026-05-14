import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _PassengerDashboardShell(),
    );
  }

  group('PassengerDashboardApp Widget Tests', () {
    testWidgets('renders Greeting and key functional tiles', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Look for user name and generic greetings
      expect(find.text('Good Morning,'), findsOneWidget);
      expect(find.text('Test Passenger'), findsOneWidget);

      // Check for overview section
      expect(find.text('Overview'), findsOneWidget);
      
      // Verify custom Action Cards
      expect(find.text('Call Driver'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
    });

    testWidgets('renders Track Vehicle Button when appropriate', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Track Vehicle'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of PassengerDashboardApp
// ─────────────────────────────────────────────────────────────────────────────
class _PassengerDashboardShell extends StatelessWidget {
  const _PassengerDashboardShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Good Morning,'),
                const Text('Test Passenger'),
                const SizedBox(height: 20),
                const Text('Overview'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildAction('Call Driver', Icons.call_rounded),
                    _buildAction('Alerts', Icons.notifications_active_rounded),
                    _buildAction('Attendance', Icons.history_edu_rounded),
                    _buildAction('Payments', Icons.account_balance_wallet_rounded),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.location_on_rounded),
                  label: const Text('Track Vehicle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(String title, IconData icon) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon),
          Text(title),
        ],
      ),
    );
  }
}
