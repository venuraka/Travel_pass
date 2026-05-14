import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project/Screens/Components/BottomBar.dart';

void main() {
  Widget createWidgetUnderTest(int selectedIndex, Function(int) onTabSelected) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      ),
      child: CustomBottomNavBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }

  group('CustomBottomNavBar Widget Tests', () {
    testWidgets('renders all 5 nav items correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest(2, (_) {}));
      await tester.pumpAndSettle();

      expect(find.text('Passenger'), findsOneWidget);
      expect(find.text('Money'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('triggers callback when a tab is clicked', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int tappedIndex = -1;

      await tester.pumpWidget(createWidgetUnderTest(2, (index) {
        tappedIndex = index;
      }));
      await tester.pumpAndSettle();

      // Tap the 'Money' tab which is at index 1
      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 1);
    });
  });
}
