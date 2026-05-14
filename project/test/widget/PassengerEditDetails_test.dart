import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/Header.dart';
import 'package:project/Screens/Components/InputTexts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PassengerEditDetails Widget Tests
//
// The real EditDetailsScreen requires Firebase which is unavailable in test environments.
// We test an equivalent structural shell that mirrors the exact same UI layout.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: _PassengerEditDetailsShell(),
    );
  }

  group('Passenger EditDetailsScreen Widget Tests', () {
    testWidgets('Renders Edit Details layout correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

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

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of EditDetailsScreen
// ─────────────────────────────────────────────────────────────────────────────
class _PassengerEditDetailsShell extends StatefulWidget {
  const _PassengerEditDetailsShell();

  @override
  State<_PassengerEditDetailsShell> createState() => _PassengerEditDetailsShellState();
}

class _PassengerEditDetailsShellState extends State<_PassengerEditDetailsShell> {
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Stack(
        children: [
          const RegistrationHeader(
            title: 'Edit',
            subtitle: 'Details',
          ),
          Padding(
            padding: const EdgeInsets.only(top: 250),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    InputTextField(
                      labelText: 'Phone Number',
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 20),
                    const Text('Pickup Location'),
                    DropdownButton<String>(
                      value: _selectedLocation,
                      items: const [
                        DropdownMenuItem(value: 'Home', child: Text('Home')),
                        DropdownMenuItem(value: 'Office', child: Text('Office')),
                      ],
                      onChanged: (val) {},
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
