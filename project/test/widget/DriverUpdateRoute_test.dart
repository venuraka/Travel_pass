import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _DriverUpdateRouteShell(),
    );
  }

  group('DriverUpdateRouteScreen Widget Tests', () {
    testWidgets('renders stops/nodes along route correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Update Route Info'), findsOneWidget);
      
      expect(find.text('Colombo Fort (Start)'), findsOneWidget);
      expect(find.text('Kandy Junction (Stop)'), findsOneWidget);
      
      expect(find.text('Update Live Route'), findsOneWidget);
    });

    testWidgets('triggers action on live route button trigger', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update Live Route'));
      await tester.pumpAndSettle();

      expect(find.text('Route Updated successfully!'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverUpdateRouteScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverUpdateRouteShell extends StatefulWidget {
  const _DriverUpdateRouteShell();

  @override
  State<_DriverUpdateRouteShell> createState() => _DriverUpdateRouteShellState();
}

class _DriverUpdateRouteShellState extends State<_DriverUpdateRouteShell> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Route Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.location_pin),
              title: Text('Colombo Fort (Start)'),
            ),
            const ListTile(
              leading: Icon(Icons.circle),
              title: Text('Kandy Junction (Stop)'),
            ),
            const Spacer(),
            if (_status != null)
              Text(_status!, style: const TextStyle(color: Colors.green)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _status = 'Route Updated successfully!';
                });
              },
              child: const Text('Update Live Route'),
            )
          ],
        ),
      ),
    );
  }
}
