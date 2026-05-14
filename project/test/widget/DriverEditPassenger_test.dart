import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Driver/EditPassenger.dart';
import 'package:project/Screens/Components/Header.dart';
import 'package:project/Screens/Components/InputTexts.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  final dummyPassenger = PassengerModel(
    uid: 'passenger123',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '0712345678',
    paymentAmount: '150',
    paymentType: 'Daily',
    pickupLocation: 'Colombo',
    driverId: 'driver123',
    vehiclePlate: 'ABC-1234',
    address: '123 Main St',
    otherPhone: '',
    createdAt: Timestamp.now(),
  );

  Widget createTestWidget() {
    return MaterialApp(
      home: EditPassengerScreen(passenger: dummyPassenger),
    );
  }

  group('Driver EditPassengerScreen Widget Tests', () {
    testWidgets('Renders Edit Passenger layout correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      
      // Allow future to complete (Database fail due to no firebase)
      await tester.pumpAndSettle();

      // Check header
      expect(find.byType(RegistrationHeader), findsOneWidget);
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

      // Check buttons
      expect(find.text('Update'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
