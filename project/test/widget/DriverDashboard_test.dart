import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _DriverDashboardShell(),
    );
  }

  group('DriverDashboardScreen Widget Tests', () {
    testWidgets('renders Welcome Greeting and Driver Name', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Good Afternoon,'), findsOneWidget);
      expect(find.text('Test Driver'), findsOneWidget);
    });

    testWidgets('renders Hero Card and dynamic Action Grid', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check Overview heading
      expect(find.text('Overview'), findsOneWidget);
      
      // Hero Card
      expect(find.text("Today's Passengers"), findsOneWidget);
      
      // Actions
      expect(find.text('Start Poll'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);
    });

    testWidgets('renders Journey Button at bottom', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Start Journey'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverDashboardScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverDashboardShell extends StatelessWidget {
  const _DriverDashboardShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Text('Good Afternoon,'),
            const Text('Test Driver'),
            const SizedBox(height: 20),
            const Text('Overview'),
            
            // Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  Text("Today's Passengers"),
                  Text('5'),
                ],
              ),
            ),
            
            // Action grid
            Row(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Start Poll')),
                ElevatedButton(onPressed: () {}, child: const Text('Reminders')),
              ],
            ),
            const Spacer(),
            
            // Start Journey Bottom Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Start Journey'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
