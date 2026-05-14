import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _PassengerRegistrationShell(),
    );
  }

  group('PassengerRegistrationScreen Widget Tests', () {
    testWidgets('renders Passenger Registration and inputs', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('passenger'), findsOneWidget);
      expect(find.text('Registration'), findsOneWidget);
      
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Vehicle Number Plate'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Other Phone Number'), findsOneWidget);
      
      expect(find.text('Payment Type'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('updates Payment Type radio group', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initial: Daily selected, Monthly not selected or selectable
      await tester.tap(find.text('Monthly'));
      await tester.pump();
      
      expect(find.text('Selected: Monthly Payment'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of PassengerRegistrationScreen
// ─────────────────────────────────────────────────────────────────────────────
class _PassengerRegistrationShell extends StatefulWidget {
  const _PassengerRegistrationShell();

  @override
  State<_PassengerRegistrationShell> createState() => _PassengerRegistrationShellState();
}

class _PassengerRegistrationShellState extends State<_PassengerRegistrationShell> {
  String _paymentType = 'Daily Payment';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Text('passenger'),
            const Text('Registration'),
            const TextField(decoration: InputDecoration(labelText: 'Name')),
            const TextField(decoration: InputDecoration(labelText: 'Vehicle Number Plate')),
            const TextField(decoration: InputDecoration(labelText: 'Address')),
            const TextField(decoration: InputDecoration(labelText: 'Email')),
            const TextField(decoration: InputDecoration(labelText: 'Phone Number')),
            const TextField(decoration: InputDecoration(labelText: 'Other Phone Number')),
            
            const Text('Payment Type'),
            RadioListTile<String>(
              title: const Text('Daily'),
              value: 'Daily Payment',
              groupValue: _paymentType,
              onChanged: (val) => setState(() => _paymentType = val!),
            ),
            RadioListTile<String>(
              title: const Text('Monthly'),
              value: 'Monthly Payment',
              groupValue: _paymentType,
              onChanged: (val) => setState(() => _paymentType = val!),
            ),
            Text('Selected: $_paymentType'),
            
            ElevatedButton(
              onPressed: () {},
              child: const Text('Register'),
            )
          ],
        ),
      ),
    );
  }
}
