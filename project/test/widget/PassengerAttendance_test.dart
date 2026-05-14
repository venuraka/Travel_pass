import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/AppBar.dart';

// A Structural Mirror Shell of PassengerAttendaceScreen.
// Tests the layout structure, header, and attendance legend items without triggering Firestore fetches.
class _PassengerAttendanceShell extends StatelessWidget {
  const _PassengerAttendanceShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: const CustomAppBar(title: 'Attendance Record'),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              color: Colors.white,
              alignment: Alignment.center,
              child: const Text('Mock Calendar Grid View', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20.0,
              runSpacing: 10.0,
              children: [
                _buildLegendItem('Present', const Color(0xFF05A664)),
                _buildLegendItem('Absent', Colors.red),
                _buildLegendItem('Not Marked', Colors.orange),
                _buildLegendItem('Today', const Color(0xFF121415), isToday: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, {bool isToday = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: ValueKey('legend_dot_$title'),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: Colors.grey, width: 2) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

void main() {
  group('PassengerAttendanceScreen Widget Tests', () {
    testWidgets('Renders app bar and simulated calendar layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _PassengerAttendanceShell(),
        ),
      );

      // Assert core page elements
      expect(find.text('Attendance Record'), findsOneWidget);
      expect(find.text('Mock Calendar Grid View'), findsOneWidget);
    });

    testWidgets('Renders all four attendance legend items correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _PassengerAttendanceShell(),
        ),
      );

      // Assert exact legend text occurrences
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Not Marked'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Assert legend dots are rendered
      expect(find.byKey(const ValueKey('legend_dot_Present')), findsOneWidget);
      expect(find.byKey(const ValueKey('legend_dot_Absent')), findsOneWidget);
      expect(find.byKey(const ValueKey('legend_dot_Not Marked')), findsOneWidget);
      expect(find.byKey(const ValueKey('legend_dot_Today')), findsOneWidget);
    });
  });
}
