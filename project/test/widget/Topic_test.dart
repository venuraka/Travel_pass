import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/Topic.dart';

void main() {
  group('PageHeader Widget Tests', () {
    testWidgets('renders title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageHeader(title: 'My Dashboard'),
          ),
        ),
      );

      expect(find.text('My Dashboard'), findsOneWidget);
      // Verify subtitle and actions are not present
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageHeader(
              title: 'Settings',
              subtitle: Text('Manage your account'),
            ),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Manage your account'), findsOneWidget);
    });

    testWidgets('renders actions when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageHeader(
              title: 'Notifications',
              actions: [
                const Icon(Icons.notifications, key: Key('notif_icon')),
                const Icon(Icons.settings, key: Key('settings_icon')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byKey(const Key('notif_icon')), findsOneWidget);
      expect(find.byKey(const Key('settings_icon')), findsOneWidget);
    });
  });
}
