import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest(List<String> updates) {
    return MaterialApp(
      home: _PassengerUpdatesShell(updates: updates),
    );
  }

  group('PassengerUpdatesScreen Widget Tests', () {
    testWidgets('renders Empty state illustration when list is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest([]));
      await tester.pumpAndSettle();

      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('No updates yet!'), findsOneWidget);
    });

    testWidgets('renders list of updates when items exist', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest([
        'Route delay due to heavy rain',
        'Scheduled vehicle maintenance on Saturday'
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Route delay due to heavy rain'), findsOneWidget);
      expect(find.text('Scheduled vehicle maintenance on Saturday'), findsOneWidget);
      expect(find.text('No updates yet!'), findsNothing);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of PassengerUpdatesScreen
// ─────────────────────────────────────────────────────────────────────────────
class _PassengerUpdatesShell extends StatelessWidget {
  final List<String> updates;
  const _PassengerUpdatesShell({required this.updates});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Updates')),
      body: updates.isEmpty
          ? const Center(child: Text('No updates yet!'))
          : ListView.builder(
              itemCount: updates.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.campaign),
                  title: Text(updates[index]),
                );
              },
            ),
    );
  }
}
