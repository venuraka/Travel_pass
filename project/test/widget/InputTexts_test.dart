import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/InputTexts.dart';

void main() {
  group('InputTextField Widget Tests', () {
    testWidgets('renders labelText and hintText correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputTextField(
              labelText: 'Test Label',
              hintText: 'Test Hint',
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Test Hint'), findsOneWidget);
    });

    testWidgets('accepts text entry and triggers onChanged callback', (WidgetTester tester) async {
      String updatedText = '';
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputTextField(
              labelText: 'Input',
              controller: controller,
              onChanged: (value) {
                updatedText = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello Flutter');
      expect(controller.text, 'Hello Flutter');
      expect(updatedText, 'Hello Flutter');
    });
  });
}
