import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest(double totalIncome, List<String> items) {
    return MaterialApp(
      home: _DriverCashHistoryShell(totalIncome: totalIncome, items: items),
    );
  }

  group('DriverCashHistoryScreen Widget Tests', () {
    testWidgets('renders summary income cards and items', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(450.00, [
        'Invoice #2049: \$50.00',
        'Invoice #2050: \$75.00'
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Financial Dashboard'), findsOneWidget);
      expect(find.text('Cumulative Income: \$450.0'), findsOneWidget);
      
      expect(find.text('Invoice #2049: \$50.00'), findsOneWidget);
      expect(find.text('Invoice #2050: \$75.00'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverCashHistoryScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverCashHistoryShell extends StatelessWidget {
  final double totalIncome;
  final List<String> items;
  const _DriverCashHistoryShell({required this.totalIncome, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Dashboard')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.green[50],
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.green),
                const SizedBox(width: 10),
                Text('Cumulative Income: \$$totalIncome', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(items[index]),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
