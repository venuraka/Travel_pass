import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/MapsBottomCard.dart';

void main() {
  group('JourneyInfoCard Widget Tests', () {
    testWidgets('displays proper times and next stop when not onboarded', (WidgetTester tester) async {
      // 1. Build our widget inside a test-friendly container (MaterialApp)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JourneyInfoCard(
              vehicleETA: 15,
              passengerETA: 5,
              nextStop: 'Colombo Fort',
              attendanceCount: 3,
              isOnboarded: false,
            ),
          ),
        ),
      );

      // 2. Verify exact text exists on screen
      expect(find.text('Vehicle Arrival'), findsOneWidget);
      expect(find.text('15 mins'), findsOneWidget);
      expect(find.text('Your Walking Time'), findsOneWidget);
      expect(find.text('5 mins'), findsOneWidget);
      expect(find.text('Next: Colombo Fort'), findsOneWidget);
      expect(find.text('Onboarded: 3'), findsOneWidget);
    });

    testWidgets('displays different strings when isOnboarded is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JourneyInfoCard(
              vehicleETA: 25,
              passengerETA: 0,
              nextStop: 'Galle Face',
              attendanceCount: 8,
              isOnboarded: true,
              hasNextPickup: true,
            ),
          ),
        ),
      );

      // When onboarded, it displays "Drop-off ETA" instead of "Vehicle Arrival"
      expect(find.text('Drop-off ETA'), findsOneWidget);
      expect(find.text('25 mins'), findsOneWidget);
      
      // It displays "Next Destination" instead of "Your Walking Time"
      expect(find.text('Next Destination'), findsOneWidget);
      expect(find.text('Galle Face'), findsOneWidget);
      
      // "Walking time" widgets should not be rendered
      expect(find.text('Your Walking Time'), findsNothing);
    });
  });
}
