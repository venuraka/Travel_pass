import 'package:flutter_test/flutter_test.dart';
import 'package:project/models/UserModel.dart';

// Minimal helper class to simulate how Firebase User objects behave
class SimpleMockFirebaseUser {
  final String uid;
  final String email;
  final String displayName;

  SimpleMockFirebaseUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });
}

void main() {
  group('MyUserModel Tests', () {
    test('should manually construct properties accurately', () {
      final model = MyUserModel(
        uid: 'usr777',
        email: 'user@app.com',
        displayName: 'John Doe',
      );

      expect(model.uid, 'usr777');
      expect(model.email, 'user@app.com');
      expect(model.displayName, 'John Doe');
    });

    test('fromFirebaseUser() should correctly read properties from dynamic user objects', () {
      final fakeFirebaseUser = SimpleMockFirebaseUser(
        uid: 'fb123',
        email: 'firebase@auth.com',
        displayName: 'Auth User',
      );

      final model = MyUserModel.fromFirebaseUser(fakeFirebaseUser);

      expect(model.uid, 'fb123');
      expect(model.email, 'firebase@auth.com');
      expect(model.displayName, 'Auth User');
    });
  });
}
