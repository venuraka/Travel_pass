import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:project/services/RealtimeDatabase.dart';

// Mock classes for RTDB interaction
class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseDatabase mockDb;
  late MockDatabaseReference mockRef;
  late RealtimeDatabaseService service;

  setUp(() {
    mockDb = MockFirebaseDatabase();
    mockRef = MockDatabaseReference();
    service = RealtimeDatabaseService(database: mockDb);

    // By default, when .ref() is called, return our mock reference chain.
    when(() => mockDb.ref(any())).thenReturn(mockRef);
    // Support chaining if nested child() or ref() is used
    when(() => mockRef.child(any())).thenReturn(mockRef);
  });

  group('RealtimeDatabaseService Tests', () {
    test('updateDriverLocation writes coordinates and timestamp to ref', () async {
      when(() => mockRef.set(any())).thenAnswer((_) async {});

      await service.updateDriverLocation('driver_123', 6.9271, 79.8612);

      // Verify it hits the correct reference node
      verify(() => mockDb.ref('status/driver_123/location')).called(1);

      // Verify serialization arguments
      final captured = verify(() => mockRef.set(captureAny())).captured.first as Map<String, dynamic>;
      expect(captured['lat'], 6.9271);
      expect(captured['lng'], 79.8612);
      expect(captured.containsKey('timestamp'), isTrue);
    });

    test('updateDriverLocation returns early if driver ID is empty', () async {
      await service.updateDriverLocation('', 6.9271, 79.8612);
      verifyNever(() => mockDb.ref(any()));
    });

    test('setOnboarded writes status and timestamp to the passenger node', () async {
      when(() => mockRef.set(any())).thenAnswer((_) async {});

      await service.setOnboarded('driver_123', 'passenger_456', true);

      verify(() => mockDb.ref('status/driver_123/passengers/passenger_456')).called(1);
      
      final captured = verify(() => mockRef.set(captureAny())).captured.first as Map<String, dynamic>;
      expect(captured['onboarded'], true);
      expect(captured.containsKey('timestamp'), isTrue);
    });

    test('updateNextStop writes target index and coordinates to next_stop node', () async {
      when(() => mockRef.set(any())).thenAnswer((_) async {});

      await service.updateNextStop('driver_123', 2, 'Main Station', 6.93, 79.85);

      verify(() => mockDb.ref('status/driver_123/next_stop')).called(1);

      final captured = verify(() => mockRef.set(captureAny())).captured.first as Map<String, dynamic>;
      expect(captured['index'], 2);
      expect(captured['target_name'], 'Main Station');
      expect(captured['target_lat'], 6.93);
      expect(captured['target_lng'], 79.85);
    });

    test('clearOnboardedPassengers deletes passenger & location nodes', () async {
      when(() => mockRef.remove()).thenAnswer((_) async {});

      await service.clearOnboardedPassengers('driver_123');

      verify(() => mockDb.ref('status/driver_123/passengers')).called(1);
      verify(() => mockDb.ref('status/driver_123/passenger_locations')).called(1);
      verify(() => mockRef.remove()).called(2);
    });

    test('getOnboardedPassengerIds fetches snapshot and extracts Map keys', () async {
      final mockSnapshot = MockDataSnapshot();
      when(() => mockSnapshot.value).thenReturn({
        'pass_1': {'onboarded': true},
        'pass_2': {'onboarded': false},
      });
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);

      final ids = await service.getOnboardedPassengerIds('driver_123');

      expect(ids.length, 2);
      expect(ids, contains('pass_1'));
      expect(ids, contains('pass_2'));
    });

    test('getOnboardedPassengerIds returns empty if no data snapshot found', () async {
      final mockSnapshot = MockDataSnapshot();
      when(() => mockSnapshot.value).thenReturn(null);
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);

      final ids = await service.getOnboardedPassengerIds('driver_123');
      expect(ids, isEmpty);
    });
  });
}
