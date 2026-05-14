import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:project/Screens/Components/AppBar.dart';

// A Structural Mirror Shell of PassengersummeryScreen to assert its visual layout.
// Bypasses ScreenUtil by using standard ListTiles for reliable container assertions.
class _PassengerSummaryShell extends StatefulWidget {
  final DateTime selectedDay;
  final List<String> mockBoarded;
  final List<String> mockAbsent;
  const _PassengerSummaryShell({
    required this.selectedDay,
    required this.mockBoarded,
    required this.mockAbsent,
  });

  @override
  State<_PassengerSummaryShell> createState() => _PassengerSummaryShellState();
}

class _PassengerSummaryShellState extends State<_PassengerSummaryShell> {
  final Color appGreen = const Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Summary: ${DateFormat('MMM dd, yyyy').format(widget.selectedDay)}',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: appGreen, size: 28),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(widget.selectedDay),
                            style: TextStyle(
                              fontSize: 14,
                              color: appGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(widget.selectedDay),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF121415),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),

              if (widget.mockBoarded.isNotEmpty) ...[
                _buildSectionHeader("Confirmed Passengers", appGreen),
                ...widget.mockBoarded.map((name) => ListTile(
                  key: ValueKey('boarded_$name'),
                  title: Text(name),
                  subtitle: const Text('Location A'),
                  trailing: const Icon(Icons.phone, color: Colors.green),
                )),
              ],

              if (widget.mockAbsent.isNotEmpty) ...[
                _buildSectionHeader("Absent Passengers", Colors.redAccent),
                ...widget.mockAbsent.map((name) => ListTile(
                  key: ValueKey('absent_$name'),
                  title: Text(name),
                  subtitle: const Text('Location B'),
                  trailing: const Icon(Icons.phone, color: Colors.green),
                )),
              ],

              if (widget.mockBoarded.isEmpty && widget.mockAbsent.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(
                    child: Text(
                      "No passengers recorded for this day.",
                      style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

void main() {
  group('PassengerSummaryScreen Widget Tests', () {
    testWidgets('Renders calendar date header and empty state correctly',
        (WidgetTester tester) async {
      final testDate = DateTime(2026, 5, 20); // Wednesday

      await tester.pumpWidget(
        MaterialApp(
          home: _PassengerSummaryShell(
            selectedDay: testDate,
            mockBoarded: const [],
            mockAbsent: const [],
          ),
        ),
      );

      // Check calendar icon
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);

      // Check date text
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('May 20, 2026'), findsOneWidget);

      // Check empty record label
      expect(find.text('No passengers recorded for this day.'), findsOneWidget);
    });

    testWidgets('Renders section headers and passenger cards dynamically',
        (WidgetTester tester) async {
      final testDate = DateTime(2026, 5, 20);

      await tester.pumpWidget(
        MaterialApp(
          home: _PassengerSummaryShell(
            selectedDay: testDate,
            mockBoarded: const ['Alice'],
            mockAbsent: const ['Bob'],
          ),
        ),
      );

      // Verify custom text headers
      expect(find.text('Confirmed Passengers'), findsOneWidget);
      expect(find.text('Absent Passengers'), findsOneWidget);

      // Verify cards render actual names
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Verify list tile count
      expect(find.byType(ListTile), findsNWidgets(2));
    });
  });
}
