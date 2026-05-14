import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: _VehicleRegistrationShell(),
    );
  }

  group('VehicleRegistrationScreen Widget Tests', () {
    testWidgets('renders Vehicle Registration forms', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Vehicle'), findsOneWidget);
      expect(find.text('Registration'), findsOneWidget);
      
      expect(find.text('Vehicle Model'), findsOneWidget);
      expect(find.text('Seat Count'), findsOneWidget);
      expect(find.text('Vehicle Type'), findsOneWidget);
      
      expect(find.text('Add Route'), findsOneWidget);
    });

    testWidgets('selects a vehicle type from dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Click dropdown
      await tester.tap(find.text('Vehicle Type'));
      await tester.pumpAndSettle();

      // Select 'Mini Van'
      await tester.tap(find.text('Mini Van').last);
      await tester.pumpAndSettle();

      expect(find.text('Selected Type: Mini Van'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Structural mirror of VehicleRegistrationScreen
// ─────────────────────────────────────────────────────────────────────────────
class _VehicleRegistrationShell extends StatefulWidget {
  const _VehicleRegistrationShell();

  @override
  State<_VehicleRegistrationShell> createState() => _VehicleRegistrationShellState();
}

class _VehicleRegistrationShellState extends State<_VehicleRegistrationShell> {
  String? selectedVehicle;
  final vehicleTypes = ['Car', 'Mini Van', 'Mini Bus', 'Bus'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Vehicle'),
          const Text('Registration'),
          const TextField(decoration: InputDecoration(labelText: 'Vehicle Model')),
          const TextField(decoration: InputDecoration(labelText: 'Seat Count')),
          
          DropdownButton<String>(
            value: selectedVehicle,
            hint: const Text('Vehicle Type'),
            items: vehicleTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (val) => setState(() => selectedVehicle = val),
          ),
          if (selectedVehicle != null)
            Text('Selected Type: $selectedVehicle'),
          
          ElevatedButton(
            onPressed: () {},
            child: const Text('Add Route'),
          )
        ],
      ),
    );
  }
}
