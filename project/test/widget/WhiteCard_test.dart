import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/Whitecard.dart';

void main() {
  group('WhiteCard Widget Tests', () {
    testWidgets('renders child content correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                WhiteCard(
                  child: const Text('Hello WhiteCard'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hello WhiteCard'), findsOneWidget);
    });

    testWidgets('applies topPadding correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                WhiteCard(
                  topPadding: 100.0,
                  child: const Text('Test Padding'),
                ),
              ],
            ),
          ),
        ),
      );

      final Positioned positioned = tester.widget(find.ancestor(
        of: find.byType(Container).first,
        matching: find.byType(Positioned),
      ));

      expect(positioned.top, 100.0);
    });
  });
}
