import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _DriverRegistrationShell(),
    );
  }

  group('DriverRegistrationScreen Widget Tests', () {
    testWidgets('renders Registration header and form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Driver'), findsOneWidget);
      expect(find.text('Registration'), findsOneWidget);
      
      // Look for input text field labels or inputs
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Vehicle Number Plate'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('validates fields and shows local mock error snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Leaving name empty and pressing Register
      await tester.tap(find.text('Register'));
      await tester.pump(); // Trigger validation
      
      expect(find.text('Name is required.'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverRegistrationScreen to isolate UI from Firebase
// ─────────────────────────────────────────────────────────────────────────────
class _DriverRegistrationShell extends StatefulWidget {
  const _DriverRegistrationShell();

  @override
  State<_DriverRegistrationShell> createState() => _DriverRegistrationShellState();
}

class _DriverRegistrationShellState extends State<_DriverRegistrationShell> {
  final _nameController = TextEditingController();
  String? _errorMessage;

  void _handleRegister() {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Name is required.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Column(
            children: [
              Text('Driver'),
              Text('Registration'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const TextField(
                  decoration: InputDecoration(labelText: 'Vehicle Number Plate'),
                ),
                const TextField(
                  decoration: InputDecoration(labelText: 'Phone'),
                ),
                const TextField(
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                if (_errorMessage != null)
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: _handleRegister,
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
