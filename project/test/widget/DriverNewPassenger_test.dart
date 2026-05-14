import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Driver/NewPassenger.dart';
import 'package:project/Screens/Components/AppBar.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: NewPassengerScreen(),
    );
  }

  group('Driver NewPassengerScreen Widget Tests', () {
    testWidgets('Renders New Passenger screen structure correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      
      // Before streams resolve, it should show a loading indicator or error handler
      await tester.pumpAndSettle();

      // Check app bar
      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('New Passenger List'), findsOneWidget);

      // Verify empty state or error state due to missing Firebase
      // It should catch the exception and print to debugPrint, then stop loading
      // Because `_unregisteredPassengers` is empty by default, we expect:
      expect(find.text('No new passengers found.'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
