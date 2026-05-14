import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// ==============================================================================
// INSTRUCTIONS FOR BEGINNERS:
// Performance Tests record frame render times, detecting "jank" (laggy screens).
//
// Run with Flutter driver to output stats:
// `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/performance_test.dart`
// ==============================================================================

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Profile Scaffolding', () {
    testWidgets('App Scrolling & Rendering Performance Profiling', (WidgetTester tester) async {
      // 1. Load the interface under test (simulating a scrollable list of items)
      await tester.pumpWidget(const PerfTestShell());

      // 2. Record performance timeline while performing complex visual operations
      await binding.watchPerformance(() async {
        final listFinder = find.byType(ListView);

        // Simulate continuous fast scrolling down the list
        await tester.fling(listFinder, const Offset(0, -500), 2000);
        await tester.pumpAndSettle();

        // Simulate scrolling back up
        await tester.fling(listFinder, const Offset(0, 500), 2000);
        await tester.pumpAndSettle();
      }, reportKey: 'scrolling_summary');
      
      // In local and CI setups, this records frame generation times to verify app smoothness!
    });
  });
}

/// A list-heavy screen used to verify UI rendering performance
class PerfTestShell extends StatelessWidget {
  const PerfTestShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: 100,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
              title: Text('Stop Reference ID #$index'),
              subtitle: Text('Checking performance rendering metrics...'),
            );
          },
        ),
      ),
    );
  }
}
