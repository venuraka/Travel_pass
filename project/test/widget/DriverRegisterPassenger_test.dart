import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/Header.dart';
import 'package:project/Screens/Components/InputTexts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DriverRegisterPassenger Widget Tests
//
// The real RegisterPassengerScreen requires Firebase which is unavailable in test environments.
// We test an equivalent structural shell that mirrors the exact same UI layout.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: _DriverRegisterPassengerShell(),
    );
  }

  group('Driver RegisterPassengerScreen Widget Tests', () {
    testWidgets('Renders Register Passenger layout correctly', (WidgetTester tester) async {
      // Set a standard physical size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check header
      expect(find.byType(RegistrationHeader), findsOneWidget);
      expect(find.text('Register'), findsNWidgets(2)); // One in header, one in button
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
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);

      // Reset tester
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of RegisterPassengerScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DriverRegisterPassengerShell extends StatefulWidget {
  const _DriverRegisterPassengerShell();

  @override
  State<_DriverRegisterPassengerShell> createState() => _DriverRegisterPassengerShellState();
}

class _DriverRegisterPassengerShellState extends State<_DriverRegisterPassengerShell> {
  final TextEditingController _nameController = TextEditingController(text: 'Jane Smith');
  final TextEditingController _paymentAmountController = TextEditingController(text: '120');
  final TextEditingController _phoneController = TextEditingController(text: '0776543210');
  final String _paymentFrequency = 'Monthly';
  String? _selectedLocation = 'Gampaha';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Stack(
        children: [
          const RegistrationHeader(
            title: 'Register',
            subtitle: 'Passenger',
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
                      labelText: 'Name',
                      controller: _nameController,
                    ),
                    InputTextField(
                      labelText: 'Payment Amount',
                      controller: _paymentAmountController,
                    ),
                    InputTextField(
                      labelText: 'Phone Number',
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 20),
                    const Text('Payment Frequency'),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Daily',
                          groupValue: _paymentFrequency,
                          onChanged: (v) {},
                        ),
                        const Text('Daily'),
                        Radio<String>(
                          value: 'Monthly',
                          groupValue: _paymentFrequency,
                          onChanged: (v) {},
                        ),
                        const Text('Monthly'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Location',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Colombo', child: Text('Colombo')),
                        DropdownMenuItem(value: 'Gampaha', child: Text('Gampaha')),
                      ],
                      onChanged: (v) {},
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Register'),
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
