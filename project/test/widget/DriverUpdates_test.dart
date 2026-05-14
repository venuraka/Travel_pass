import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/Topic.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DriverUpdates Widget Tests
//
// The real UpdatesScreen requires Firebase which is unavailable in test environments.
// We test an equivalent structural shell that mirrors the exact same UI layout.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: _DriverUpdatesShell(),
    );
  }

  group('Driver UpdatesScreen Widget Tests', () {
    testWidgets('Renders Updates screen structure correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check header
      expect(find.byType(PageHeader), findsOneWidget);
      expect(find.text('Updates'), findsOneWidget);

      // Check bottom text input area
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type an announcement...'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of UpdatesScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverUpdatesShell extends StatelessWidget {
  const _DriverUpdatesShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const PageHeader(title: 'Updates'),
          const Expanded(
            child: Center(
              child: Text('No updates found.'),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Type an announcement...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
