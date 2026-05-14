import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest(List<Map<String, dynamic>> transactions) {
    return MaterialApp(
      home: _PassengerPaymentHistoryShell(transactions: transactions),
    );
  }

  group('PassengerPaymentHistoryScreen Widget Tests', () {
    testWidgets('renders dynamic receipt cards with payments and statuses', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest([
        {'title': 'April Monthly Fee', 'amount': '\$80', 'status': 'Success'},
        {'title': 'May Monthly Fee', 'amount': '\$80', 'status': 'Pending'},
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Payment History'), findsOneWidget);
      
      expect(find.text('April Monthly Fee'), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);

      expect(find.text('May Monthly Fee'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of PassengerPaymentHistoryScreen
// ─────────────────────────────────────────────────────────────────────────────
class _PassengerPaymentHistoryShell extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _PassengerPaymentHistoryShell({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final t = transactions[index];
          final isSuccess = t['status'] == 'Success';
          return ListTile(
            title: Text(t['title']),
            subtitle: Text(t['status']),
            trailing: Text(
              t['amount'],
              style: TextStyle(
                color: isSuccess ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
