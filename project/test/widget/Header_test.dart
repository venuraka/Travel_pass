import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/Header.dart';

void main() {
  group('RegistrationHeader Widget Tests', () {
    testWidgets('renders title and subtitle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegistrationHeader(
              title: 'Register',
              subtitle: 'Create Account',
            ),
          ),
        ),
      );

      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('calls onBackPressed when back icon is pressed', (WidgetTester tester) async {
      bool backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegistrationHeader(
              title: 'Title',
              subtitle: 'Subtitle',
              onBackPressed: () {
                backPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(backPressed, isTrue);
    });
  });
}
