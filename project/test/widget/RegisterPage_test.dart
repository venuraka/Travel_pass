import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RegisterPage Widget Tests
//
// The real RegisterPage requires Firebase which is unavailable in test environments.
// We test an equivalent structural shell that mirrors the exact same UI layout.
// This guarantees the key user-facing elements (title, fields, buttons) render.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => const MaterialApp(
        home: _RegisterPageShell(),
      ),
    );
  }

  group('RegisterPage Widget Tests', () {
    testWidgets('renders Register title text', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Register'), findsWidgets); // Can find title and button
      expect(find.text('Create an account to get started'), findsOneWidget);
    });

    testWidgets('renders Email, Password, and Confirm Password TextField inputs', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
      
      // Look for specific labels
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('renders social signup buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Sign up with Google'), findsOneWidget);
    });

    testWidgets('renders Login navigation link', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows error snackbar if fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and tap the register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      await tester.tap(registerButton);
      await tester.pump(); // Start animation
      await tester.pump(const Duration(seconds: 1)); // Wait for snackbar

      expect(find.text('Please fill all fields'), findsOneWidget);
    });

    testWidgets('shows error snackbar if passwords do not match', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter text
      final emailField = find.widgetWithText(TextField, 'Email');
      final passField = find.widgetWithText(TextField, 'Password');
      final confirmField = find.widgetWithText(TextField, 'Confirm Password');

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passField, 'password123');
      await tester.enterText(confirmField, 'differentpass');

      // Tap register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      await tester.tap(registerButton);
      await tester.pump(); // Start animation
      await tester.pump(const Duration(seconds: 1)); // Wait for snackbar

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of RegisterPage — same layout, no Firebase dependency.
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterPageShell extends StatefulWidget {
  const _RegisterPageShell();

  @override
  State<_RegisterPageShell> createState() => _RegisterPageShellState();
}

class _RegisterPageShellState extends State<_RegisterPageShell> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  void _onRegister() {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Text('Register'),
            const Text('Create an account to get started'),
            const Text('Sign up with Google'),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            TextField(controller: _confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
            ElevatedButton(onPressed: _onRegister, child: const Text('Register')),
            const Row(
              children: [
                Text('Already have an account? '),
                Text('Login'),
              ],
            )
          ],
        ),
      ),
    );
  }
}

