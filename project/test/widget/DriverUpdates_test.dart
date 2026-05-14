import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Driver/Updates.dart';
import 'package:project/Screens/Components/Topic.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: UpdatesScreen(),
    );
  }

  group('Driver UpdatesScreen Widget Tests', () {
    testWidgets('Renders Updates screen structure correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      
      // Before stream settles, it should show a loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for stream future resolution (which will fail gracefully without firebase)
      await tester.pumpAndSettle();

      // Check header
      expect(find.byType(PageHeader), findsOneWidget);
      expect(find.text('Updates'), findsOneWidget);

      // Check bottom text input area
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type an announcement...'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
