import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Driver/PaymentHistory.dart';
import 'package:project/Screens/Components/AppBar.dart';
import 'package:project/Screens/Components/Topic.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: PaymentHistoryScreen(),
    );
  }

  group('Driver PaymentHistoryScreen Widget Tests', () {
    testWidgets('Renders Payment History structure correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      
      // Before streams resolve, a loading indicator or 'No payment history' might appear
      // Let's pump and settle to allow streams to process
      await tester.pumpAndSettle();

      // Check app bar
      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('Payment History'), findsOneWidget);

      // Check page header
      expect(find.byType(PageHeader), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
