import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/CustomSnackBar.dart';

void main() {
  group('CustomSnackBar Widget Tests', () {
    testWidgets('shows success snackbar with correct color and message', (WidgetTester tester) async {
      // Build a scaffold to show the snackbar
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CustomSnackBar.showSuccess(context, 'Success message');
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger the snackbar
      await tester.tap(find.text('Show Success'));
      await tester.pump(); // Pump to start the animation

      // Verify the snackbar text
      expect(find.text('Success message'), findsOneWidget);

      // Verify the color
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);
      final SnackBar snackBar = tester.widget(snackBarFinder);
      expect(snackBar.backgroundColor, CustomSnackBar.successColor);
    });

    testWidgets('shows error snackbar with correct color and message', (WidgetTester tester) async {
      // Build a scaffold to show the snackbar
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CustomSnackBar.showError(context, 'Error message');
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger the snackbar
      await tester.tap(find.text('Show Error'));
      await tester.pump(); // Pump to start the animation

      // Verify the snackbar text
      expect(find.text('Error message'), findsOneWidget);

      // Verify the color
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);
      final SnackBar snackBar = tester.widget(snackBarFinder);
      expect(snackBar.backgroundColor, CustomSnackBar.errorColor);
    });
  });
}
