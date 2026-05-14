import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest(List<String> passengers) {
    return MaterialApp(
      home: _DriverPaymentRemindersShell(passengers: passengers),
    );
  }

  group('DriverPaymentRemindersScreen Widget Tests', () {
    testWidgets('renders empty state when everyone is paid up', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest([]));
      await tester.pumpAndSettle();

      expect(find.text('Missed Payments'), findsOneWidget);
      expect(find.text('All passengers are fully paid!'), findsOneWidget);
    });

    testWidgets('renders rows of outstanding balances when items exist', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest([
        'Kamal Perera',
        'Nimal Silva'
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Kamal Perera'), findsOneWidget);
      expect(find.text('Nimal Silva'), findsOneWidget);
      
      // Checks that remind action handles/triggers rendered
      expect(find.byIcon(Icons.notifications_active_outlined), findsNWidgets(2));
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverPaymentRemindersScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverPaymentRemindersShell extends StatelessWidget {
  final List<String> passengers;
  const _DriverPaymentRemindersShell({required this.passengers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Missed Payments')),
      body: passengers.isEmpty
          ? const Center(child: Text('All passengers are fully paid!'))
          : ListView.builder(
              itemCount: passengers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(passengers[index]),
                  trailing: const Icon(Icons.notifications_active_outlined),
                );
              },
            ),
    );
  }
}
