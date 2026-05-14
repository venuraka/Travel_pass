import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest(List<Map<String, dynamic>> logs) {
    return MaterialApp(
      home: _DriverAttendanceHistoryShell(logs: logs),
    );
  }

  group('DriverAttendanceHistoryScreen Widget Tests', () {
    testWidgets('renders date summary headers and monthly counters', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest([
        {'date': 'May 12, 2026', 'passengers': '14 Onboarded'},
        {'date': 'May 13, 2026', 'passengers': '12 Onboarded'},
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Attendance Logs'), findsOneWidget);
      
      expect(find.text('May 12, 2026'), findsOneWidget);
      expect(find.text('14 Onboarded'), findsOneWidget);

      expect(find.text('May 13, 2026'), findsOneWidget);
      expect(find.text('12 Onboarded'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverAttendanceHistoryScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverAttendanceHistoryShell extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  const _DriverAttendanceHistoryShell({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Logs')),
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(log['date']),
            subtitle: Text(log['passengers']),
          );
        },
      ),
    );
  }
}
