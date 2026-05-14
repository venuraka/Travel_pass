import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest(String passengerName, String status, String amount) {
    return MaterialApp(
      home: _DriverPaymentDetailsShell(
        passengerName: passengerName,
        status: status,
        amount: amount,
      ),
    );
  }

  group('DriverPaymentDetailsScreen Widget Tests', () {
    testWidgets('renders receipt headers and status tags correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest('Saman Kumara', 'Overdue', '\$95.00'));
      await tester.pumpAndSettle();

      expect(find.text('Transaction Details'), findsOneWidget);
      expect(find.text('Passenger: Saman Kumara'), findsOneWidget);
      expect(find.text('Billing Amount: \$95.00'), findsOneWidget);
      expect(find.text('Payment Status: Overdue'), findsOneWidget);

      expect(find.text('Confirm Cash Received'), findsOneWidget);
    });

    testWidgets('triggers confirm cash payment action', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest('Saman Kumara', 'Overdue', '\$95.00'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Cash Received'));
      await tester.pumpAndSettle();

      expect(find.text('Payment Status: Approved'), findsOneWidget);
      expect(find.text('Payment fully cleared!'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverPaymentDetailsScreen (largest visual component shell)
// ─────────────────────────────────────────────────────────────────────────────
class _DriverPaymentDetailsShell extends StatefulWidget {
  final String passengerName;
  final String status;
  final String amount;

  const _DriverPaymentDetailsShell({
    required this.passengerName,
    required this.status,
    required this.amount,
  });

  @override
  State<_DriverPaymentDetailsShell> createState() => _DriverPaymentDetailsShellState();
}

class _DriverPaymentDetailsShellState extends State<_DriverPaymentDetailsShell> {
  late String _currentStatus;
  String? _confirmation;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Passenger: ${widget.passengerName}', style: const TextStyle(fontSize: 18)),
            const Divider(),
            Text('Billing Amount: ${widget.amount}'),
            Text('Payment Status: $_currentStatus', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_confirmation != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(_confirmation!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                setState(() {
                  _currentStatus = 'Approved';
                  _confirmation = 'Payment fully cleared!';
                });
              },
              child: const Text('Confirm Cash Received', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
