import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// ==============================================================================
// INSTRUCTIONS FOR BEGINNERS:
// Integration & E2E Tests spin up the ACTUAL running application on a device/browser,
// whereas Unit/Widget tests run headlessly in a virtual test bench.
// 
// To run this on your computer:
// `flutter test integration_test/app_test.dart`
// ==============================================================================

void main() {
  // 1. Initializes the integration test environment
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E / Integration Flow Scaffolding', () {
    testWidgets('User Flow: Verify state changes across interactive components', (WidgetTester tester) async {
      // 2. Load the initial UI screen (In a real app, you might call app.main())
      await tester.pumpWidget(const E2ETestShell());

      // 3. Check initial state: should say "Welcome to TravelPass"
      expect(find.text('Welcome to TravelPass'), findsOneWidget);
      expect(find.text('Status: Not Started'), findsOneWidget);

      // 4. Perform a User Action: Tap the "Start Journey" Button
      final Finder startBtn = find.byType(ElevatedButton);
      await tester.tap(startBtn);

      // 5. Re-draw the screen after the tap (Wait for animations to finish)
      await tester.pumpAndSettle();

      // 6. Check final state: UI should now update to "Status: Driving"
      expect(find.text('Status: Driving'), findsOneWidget);
      expect(find.text('Welcome to TravelPass'), findsNothing);
    });
  });
}

/// A standalone mini-app simulating a user journey screen to ensure 
/// the integration tests compile and run correctly without requiring 
/// a connected backend (Firebase) right away.
class E2ETestShell extends StatefulWidget {
  const E2ETestShell({super.key});

  @override
  State<E2ETestShell> createState() => _E2ETestShellState();
}

class _E2ETestShellState extends State<E2ETestShell> {
  bool _hasStarted = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Integration Test Bench')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_hasStarted) const Text('Welcome to TravelPass'),
              const SizedBox(height: 20),
              Text(_hasStarted ? 'Status: Driving' : 'Status: Not Started'),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasStarted = true;
                  });
                },
                child: const Text('START JOURNEY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
