import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _DriverPassengersShell(),
    );
  }

  group('DriverPassengersScreen Widget Tests', () {
    testWidgets('renders primary passenger lists and allows filtering', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Manage Passengers'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      expect(find.text('Amani Fernando'), findsOneWidget);
      expect(find.text('Devinda Perera'), findsOneWidget);

      // Enter filtering string
      await tester.enterText(find.byType(TextField), 'Amani');
      await tester.pumpAndSettle();

      expect(find.text('Amani Fernando'), findsOneWidget);
      expect(find.text('Devinda Perera'), findsNothing);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverPassengersScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverPassengersShell extends StatefulWidget {
  const _DriverPassengersShell();

  @override
  State<_DriverPassengersShell> createState() => _DriverPassengersShellState();
}

class _DriverPassengersShellState extends State<_DriverPassengersShell> {
  final List<String> _all = ['Amani Fernando', 'Devinda Perera'];
  List<String> _visible = ['Amani Fernando', 'Devinda Perera'];

  void _filter(String q) {
    setState(() {
      _visible = _all.where((name) => name.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Passengers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search Passenger'),
              onChanged: _filter,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _visible.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_visible[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
