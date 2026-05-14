import 'package:flutter_test/flutter_test.dart';
import 'package:project/models/DriverModel.dart';

void main() {
  group('DriverModel Unit Tests', () {
    test('toMap() returns expected map structure and default values', () {
      // 1. Set up the test data (the input)
      final driver = DriverModel(
        uid: 'drv_123',
        name: 'Test Driver',
        vehiclePlate: 'ABC-1234',
        phone: '+1234567890',
        email: 'driver@test.com',
      );

      // 2. Execute the action we want to test
      final driverMap = driver.toMap();

      // 3. Assert (verify) that the resulting data matches our expectations
      expect(driverMap['uid'], 'drv_123');
      expect(driverMap['name'], 'Test Driver');
      expect(driverMap['vehiclePlate'], 'ABC-1234');
      expect(driverMap['phone'], '+1234567890');
      expect(driverMap['email'], 'driver@test.com');
      
      // Verify default values initialized inside the model constructor
      expect(driverMap['isJourneyStarted'], false);
      expect(driverMap['balance'], 0.0);
      expect(driverMap['badgePreference'], 'Both');
      expect(driverMap['isVerified'], false);
      expect(driverMap['role'], 'driver'); // The model injects static 'driver' role
    });

    test('toMap() handles non-required parameters properly', () {
      final driver = DriverModel(
        uid: 'drv_456',
        name: 'Alice',
        vehiclePlate: 'XYZ-9876',
        phone: '+987654321',
        email: 'alice@test.com',
        seatCount: 4,
        vehicleModel: 'Toyota Prius',
        vehicleType: 'Car',
      );

      final driverMap = driver.toMap();

      expect(driverMap['seatCount'], 4);
      expect(driverMap['vehicleModel'], 'Toyota Prius');
      expect(driverMap['vehicleType'], 'Car');
    });
  });
}
