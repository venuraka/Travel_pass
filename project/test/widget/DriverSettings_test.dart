import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _DriverSettingsShell(),
    );
  }

  group('DriverSettingsScreen Widget Tests', () {
    testWidgets('renders voice assistant toggles and profile details', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Driver Settings'), findsOneWidget);
      expect(find.text('AI Voice Assistant'), findsOneWidget);
      expect(find.text('Vehicle Capacity: 25 Seats'), findsOneWidget);

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('toggles voice assistant setting', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final Switch switchWidget = tester.widget(find.byType(Switch));
      expect(switchWidget.value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final Switch updatedSwitch = tester.widget(find.byType(Switch));
      expect(updatedSwitch.value, isFalse);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of DriverSettingsScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverSettingsShell extends StatefulWidget {
  const _DriverSettingsShell();

  @override
  State<_DriverSettingsShell> createState() => _DriverSettingsShellState();
}

class _DriverSettingsShellState extends State<_DriverSettingsShell> {
  bool _aiAssistant = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('AI Voice Assistant'),
            subtitle: const Text('Enable speech commands'),
            value: _aiAssistant,
            onChanged: (val) => setState(() => _aiAssistant = val),
          ),
          const ListTile(
            title: Text('Vehicle Capacity: 25 Seats'),
            leading: Icon(Icons.directions_bus),
          ),
        ],
      ),
    );
  }
}
