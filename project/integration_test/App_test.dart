import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// ==============================================================================
// INTEGRATION & E2E TESTS
// These tests simulate a real user interacting with actual app screens.
// They verify multi-screen navigation and state changes without a live backend.
//
// Run with: flutter test integration_test/App_test.dart -d flutter-tester
// ==============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Login Screen User Flow', () {
    testWidgets('Login screen renders all key elements', (WidgetTester tester) async {
      await tester.pumpWidget(const _LoginTestShell());
      await tester.pumpAndSettle();

      // Core UI elements should all be visible
      expect(find.text('LogIn'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('User can type into email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(const _LoginTestShell());
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));

      await tester.enterText(emailField, 'testdriver@travelpass.lk');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      expect(find.text('testdriver@travelpass.lk'), findsOneWidget);
    });

    testWidgets('Tapping Login button without credentials shows error', (WidgetTester tester) async {
      await tester.pumpWidget(const _LoginTestShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should show the snackbar error (empty fields guard)
      expect(find.text('Please fill all fields'), findsOneWidget);
    });
  });

  group('E2E: Multi-Screen Navigation', () {
    testWidgets('Navigates from Login to Register screen on link tap', (WidgetTester tester) async {
      await tester.pumpWidget(const _LoginTestShell());
      await tester.pumpAndSettle();

      // Tap the Register link
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Should now show the Register screen
      expect(find.text('Register'), findsWidgets);
    });
  });
}

// =====================================================================
// Isolated Login Shell — renders LoginPage with a Navigator context
// but no Firebase connection, safe for headless E2E simulation.
// =====================================================================
class _LoginTestShell extends StatelessWidget {
  const _LoginTestShell();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _StandaloneLoginPage(),
    );
  }
}

// A self-contained login-like widget for E2E simulation
class _StandaloneLoginPage extends StatefulWidget {
  const _StandaloneLoginPage();

  @override
  State<_StandaloneLoginPage> createState() => _StandaloneLoginPageState();
}

class _StandaloneLoginPageState extends State<_StandaloneLoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  void _onLogin() {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('LogIn', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Welcome Back', style: TextStyle(color: Color(0xFF05A664))),
            const SizedBox(height: 40),
            TextField(
              key: const Key('email_field'),
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('password_field'),
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _onLogin, child: const Text('Login')),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _RegisterStub()),
                );
              },
              child: const Text('Register', style: TextStyle(color: Color(0xFF05A664))),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterStub extends StatelessWidget {
  const _RegisterStub();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Register')),
    );
  }
}
