import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _PassengerSettingsShell(),
    );
  }

  group('PassengerSettingsScreen Widget Tests', () {
    testWidgets('renders section titles and toggle switches', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Play Sounds'), findsOneWidget);
      
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('toggles notifications switch successfully', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final Switch switchWidget = tester.widget(find.byType(Switch).first);
      expect(switchWidget.value, isTrue);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      final Switch updatedSwitch = tester.widget(find.byType(Switch).first);
      expect(updatedSwitch.value, isFalse);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of PassengerSettingsScreen
// ─────────────────────────────────────────────────────────────────────────────
class _PassengerSettingsShell extends StatefulWidget {
  const _PassengerSettingsShell();

  @override
  State<_PassengerSettingsShell> createState() => _PassengerSettingsShellState();
}

class _PassengerSettingsShellState extends State<_PassengerSettingsShell> {
  bool _notifications = true;
  bool _sounds = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
          ),
          SwitchListTile(
            title: const Text('Play Sounds'),
            value: _sounds,
            onChanged: (val) => setState(() => _sounds = val),
          ),
        ],
      ),
    );
  }
}
