import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project/Screens/Components/Cards.dart';

void main() {
  Widget createWidgetUnderTest(Widget card) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) => MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
      child: card,
    );
  }

  group('InfoCard Widget Tests', () {
    testWidgets('renders title and trailing widget correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        const InfoCard(
          title: 'Test Title',
          subtitle: 'Test Subtitle',
          trailing: Text('\$50'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.text('\$50'), findsOneWidget);
    });

    testWidgets('renders Monthly tag badge when showTag is true', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        const InfoCard(
          title: 'Test',
          trailing: Icon(Icons.arrow_forward),
          showTag: true,
          tagText: 'Monthly',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('renders Payment Method tag when provided', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        const InfoCard(
          title: 'Test',
          trailing: Icon(Icons.arrow_forward),
          paymentMethod: 'Cash',
        ),
      ));
      await tester.pumpAndSettle();

      // The widget capitalizes the payment method
      expect(find.text('CASH'), findsOneWidget);
    });
  });
}
