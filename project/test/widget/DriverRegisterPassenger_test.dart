import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Driver/RegisterPassenger.dart';
import 'package:project/Screens/Components/Header.dart';
import 'package:project/Screens/Components/InputTexts.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  final dummyPassenger = PassengerModel(
    uid: 'passenger123',
    name: 'Jane Smith',
    email: 'jane@example.com',
    phone: '0776543210',
    paymentAmount: '120',
    paymentType: 'Monthly',
    pickupLocation: 'Gampaha',
    driverId: 'driver123',
    vehiclePlate: 'ABC-1234',
    address: '123 Main St',
    otherPhone: '',
    createdAt: Timestamp.now(),
  );

  Widget createTestWidget() {
    return MaterialApp(
      home: RegisterPassengerScreen(
        passenger: dummyPassenger,
        pickupLocations: const ['Colombo', 'Gampaha', 'Kandy', 'Galle'],
      ),
    );
  }

  group('Driver RegisterPassengerScreen Widget Tests', () {
    testWidgets('Renders Register Passenger layout correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check header
      expect(find.byType(RegistrationHeader), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Passenger'), findsOneWidget);

      // Check input fields
      expect(find.byType(InputTextField), findsWidgets);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Payment Amount'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);

      // Check radio buttons for Payment Frequency
      expect(find.text('Payment Frequency'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      // Check Dropdown for Pickup Location
      expect(find.text('Pickup Location'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Check buttons
      expect(find.text('Register'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
