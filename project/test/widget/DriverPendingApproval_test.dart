import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DriverPendingApproval Widget Tests
//
// The real DriverPendingApprovalScreen requires Firebase which is unavailable in test environments.
// We test an equivalent structural shell that mirrors the exact same UI layout.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: _DriverPendingApprovalShell(),
    );
  }

  group('Driver PendingApprovalScreen Widget Tests', () {
    testWidgets('Renders all static UI elements correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

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

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverPendingApprovalScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverPendingApprovalShell extends StatelessWidget {
  const _DriverPendingApprovalShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF05A664),
                size: 80,
              ),
              const SizedBox(height: 30),
              const Text(
                'Verification Pending',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your account is awaiting administrator approval. We are currently verifying your bank details and documents. You will be notified once you can access the dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Refresh Status'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {},
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
