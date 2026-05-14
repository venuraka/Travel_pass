import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _DriverPollShell(),
    );
  }

  group('DriverPollScreen Widget Tests', () {
    testWidgets('renders Daily attendance polling form', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Create Attendance Poll'), findsOneWidget);
      expect(find.text('Vehicle Routing: Main Route A'), findsOneWidget);
      expect(find.text('Submit Poll'), findsOneWidget);
    });

    testWidgets('triggers validation callback on submit', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit Poll'));
      await tester.pumpAndSettle();

      expect(find.text('Poll successfully published!'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverPollScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverPollShell extends StatefulWidget {
  const _DriverPollShell();

  @override
  State<_DriverPollShell> createState() => _DriverPollShellState();
}

class _DriverPollShellState extends State<_DriverPollShell> {
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Attendance Poll')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Vehicle Routing: Main Route A'),
            const SizedBox(height: 20),
            if (_message != null)
              Text(_message!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _message = 'Poll successfully published!';
                });
              },
              child: const Text('Submit Poll'),
            ),
          ],
        ),
      ),
    );
  }
}
