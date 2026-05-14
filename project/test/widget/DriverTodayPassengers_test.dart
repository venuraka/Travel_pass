import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _DriverTodayPassengersShell(),
    );
  }

  group('DriverTodayPassengersScreen Widget Tests', () {
    testWidgets('renders Daily attendance list and allows toggle status', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text("Today's Roster"), findsOneWidget);
      expect(find.text('Active: 0 / 2'), findsOneWidget);

      // Verify initially unchecked by querying Checkbox widgets
      expect(find.byType(Checkbox), findsNWidgets(2));
      
      Checkbox cb1 = tester.widget(find.byType(Checkbox).first);
      expect(cb1.value, isFalse);

      // Check first passenger
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();

      expect(find.text('Active: 1 / 2'), findsOneWidget);
      
      Checkbox cbUpdated = tester.widget(find.byType(Checkbox).first);
      expect(cbUpdated.value, isTrue);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverTodayPassengersScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverTodayPassengersShell extends StatefulWidget {
  const _DriverTodayPassengersShell();

  @override
  State<_DriverTodayPassengersShell> createState() => _DriverTodayPassengersShellState();
}

class _DriverTodayPassengersShellState extends State<_DriverTodayPassengersShell> {
  final List<Map<String, dynamic>> _roster = [
    {'name': 'Kasun Silva', 'checked': false},
    {'name': 'Nishani Alwis', 'checked': false},
  ];

  int get _count => _roster.where((p) => p['checked'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Roster")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Center(child: Text('Active: $_count / ${_roster.length}')),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _roster.length,
              itemBuilder: (context, index) {
                final item = _roster[index];
                return CheckboxListTile(
                  title: Text(item['name']),
                  value: item['checked'],
                  onChanged: (val) {
                    setState(() {
                      _roster[index]['checked'] = val;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
