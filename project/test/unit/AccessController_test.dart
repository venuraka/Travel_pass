import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controllers/AccessController.dart';

// Nested Firestore Mock Definitions
class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirestore mockDb;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockDocumentSnapshot mockSnapshot;
  late AccessController controller;

  setUp(() {
    mockDb = MockFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    controller = AccessController(db: mockDb);

    // Standard cascading stub setup: db.collection().doc()
    when(() => mockDb.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);
  });

  group('AccessController Tests', () {
    const tUid = 'usr_123';

    test('checkPassengerStatus returns true if document registered is true', () async {
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'registered': true});

      final isRegistered = await controller.checkPassengerStatus(tUid);

      expect(isRegistered, true);
      verify(() => mockDb.collection('passenger')).called(1);
      verify(() => mockCollection.doc(tUid)).called(1);
    });

    test('checkPassengerStatus returns false if document registered is missing or false', () async {
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'registered': false});

      final isRegistered = await controller.checkPassengerStatus(tUid);

      expect(isRegistered, false);
    });

    test('isDriver returns true if driver document exists', () async {
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);

      final result = await controller.isDriver(tUid);

      expect(result, true);
      verify(() => mockDb.collection('driver')).called(1);
    });

    test('isDriverApproved returns true only if isVerified is flagged true', () async {
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'isVerified': true});

      final isApproved = await controller.isDriverApproved(tUid);

      expect(isApproved, true);
    });

    test('isDriverApproved handles exceptions and returns false safely', () async {
      when(() => mockDocument.get()).thenThrow(FirebaseException(plugin: 'firestore', code: 'unavailable'));

      final result = await controller.isDriverApproved(tUid);

      // Should catch and return false safely without crashing
      expect(result, false);
    });
  });
}
