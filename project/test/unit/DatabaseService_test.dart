import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/models/DriverModel.dart';
import 'package:project/services/Database.dart';

// Define Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockQuery mockQuery;
  late DatabaseService service;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockQuery = MockQuery();
    service = DatabaseService(firestore: mockFirestore);

    // Default collection setup
    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    
    // Default document setup
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);

    // Query chaining setup
    when(() => mockCollection.where(
          any(),
          isEqualTo: any(named: 'isEqualTo'),
          isNotEqualTo: any(named: 'isNotEqualTo'),
          isLessThan: any(named: 'isLessThan'),
          isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo'),
          isGreaterThan: any(named: 'isGreaterThan'),
          isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'),
          arrayContains: any(named: 'arrayContains'),
          arrayContainsAny: any(named: 'arrayContainsAny'),
          whereIn: any(named: 'whereIn'),
          whereNotIn: any(named: 'whereNotIn'),
          isNull: any(named: 'isNull'),
        )).thenReturn(mockQuery);

    when(() => mockQuery.limit(any())).thenReturn(mockQuery);
  });

  group('DatabaseService Tests', () {
    final testDriver = DriverModel(
      uid: 'drv_111',
      name: 'John Doe',
      email: 'john@test.com',
      phone: '0777123456',
      vehiclePlate: 'WP AAA-1234',
      vehicleModel: 'Toyota Hiace',
      seatCount: 14,
      vehicleType: 'Van',
      isVerified: true,
      route: [],
    );

    test('saveDriverData writes driver payload via set() to driver/uid', () async {
      when(() => mockDocument.set(any())).thenAnswer((_) async {});

      await service.saveDriverData(testDriver);

      verify(() => mockFirestore.collection('driver')).called(1);
      verify(() => mockCollection.doc('drv_111')).called(1);
      
      final captured = verify(() => mockDocument.set(captureAny())).captured.first as Map;
      expect(captured['uid'], 'drv_111');
      expect(captured['name'], 'John Doe');
      expect(captured['vehiclePlate'], 'WP AAA-1234');
    });

    test('updateDriverRoute sends updated route array via update()', () async {
      when(() => mockDocument.update(any())).thenAnswer((_) async {});

      final mockRoute = [{'name': 'Colombo Fort', 'lat': 6.9, 'lng': 79.8}];
      
      await service.updateDriverRoute('drv_111', mockRoute);

      verify(() => mockFirestore.collection('driver')).called(1);
      verify(() => mockCollection.doc('drv_111')).called(1);

      final captured = verify(() => mockDocument.update(captureAny())).captured.first as Map;
      expect(captured['route'], equals(mockRoute));
    });

    test('getDriverByPlate performs precise query and returns first matched map', () async {
      final mockSnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      when(() => mockDocSnapshot.data()).thenReturn({
        'uid': 'drv_111',
        'name': 'John Doe',
        'vehiclePlate': 'WP AAA-1234',
      });
      
      when(() => mockSnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final result = await service.getDriverByPlate('WP AAA-1234');

      verify(() => mockFirestore.collection('driver')).called(1);
      verify(() => mockCollection.where('vehiclePlate', isEqualTo: 'WP AAA-1234')).called(1);
      verify(() => mockQuery.limit(1)).called(1);
      
      expect(result, isNotNull);
      expect(result!['uid'], 'drv_111');
      expect(result['vehiclePlate'], 'WP AAA-1234');
    });

    test('getDriverByPlate returns null when query snapshot is empty', () async {
      final mockSnapshot = MockQuerySnapshot();
      when(() => mockSnapshot.docs).thenReturn([]);
      when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final result = await service.getDriverByPlate('WP AAA-1234');

      expect(result, isNull);
    });

    test('searchVehiclePlates fetches all documents and filters by lowercase sub-query', () async {
      final mockSnapshot = MockQuerySnapshot();
      final doc1 = MockQueryDocumentSnapshot();
      final doc2 = MockQueryDocumentSnapshot();

      when(() => doc1.data()).thenReturn({'vehiclePlate': 'WP AAA-1111'});
      when(() => doc2.data()).thenReturn({'vehiclePlate': 'SP BBB-2222'});

      when(() => mockSnapshot.docs).thenReturn([doc1, doc2]);
      when(() => mockCollection.get()).thenAnswer((_) async => mockSnapshot);

      // Filter for "aaa"
      final results = await service.searchVehiclePlates('aaa');

      expect(results.length, 1);
      expect(results.first, 'WP AAA-1111');
    });
  });
}
