import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/passenger/EditDetails.dart';
import 'package:project/Screens/Components/Header.dart';
import 'package:project/Screens/Components/InputTexts.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: EditDetailsScreen(),
    );
  }

  group('Passenger EditDetailsScreen Widget Tests', () {
    testWidgets('Renders Edit Details layout correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      
      // Settle the futures (Firebase fails gracefully)
      await tester.pumpAndSettle();

      // Check header
      expect(find.byType(RegistrationHeader), findsOneWidget);

      // Check inputs
      expect(find.byType(InputTextField), findsOneWidget);
      expect(find.text('Pickup Location'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      
      // Check buttons
      expect(find.text('Update'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
