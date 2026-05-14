import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/controllers/AuthService.dart';
import 'package:project/models/UserModel.dart';

// Set up our mock tail definitions
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late AuthService authService;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();

    // Initialize the AuthService with the Mocked Firebase instance (Dependency Injection!)
    authService = AuthService(auth: mockFirebaseAuth);
  });

  group('AuthService Tests', () {
    const tEmail = 'user@test.com';
    const tPassword = 'password123';
    const tUid = 'mock_uid_123';

    test('signUpWithEmail successfully creates user and updates name', () async {
      // Prepare standard mock behaviors
      when(() => mockUser.uid).thenReturn(tUid);
      when(() => mockUser.email).thenReturn(tEmail);
      when(() => mockUser.displayName).thenReturn('Antigravity Developer');
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async => {});
      when(() => mockUser.reload()).thenAnswer((_) async => {});

      when(() => mockUserCredential.user).thenReturn(mockUser);
      
      // Mock method behaviors on FirebaseAuth
      when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
        email: tEmail,
        password: tPassword,
      )).thenAnswer((_) async => mockUserCredential);

      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

      // Run the service method
      final userModel = await authService.signUpWithEmail(
        tEmail,
        tPassword,
        name: 'Antigravity Developer',
      );

      // Assertions
      expect(userModel, isNotNull);
      expect(userModel?.uid, tUid);
      expect(userModel?.displayName, 'Antigravity Developer');
      
      // Verify that internal calls were triggered correctly
      verify(() => mockFirebaseAuth.createUserWithEmailAndPassword(
        email: tEmail,
        password: tPassword,
      )).called(1);
    });

    test('loginWithEmail returns valid MyUserModel upon successful mock sign in', () async {
      // Mocks
      when(() => mockUser.uid).thenReturn('login_uid');
      when(() => mockUser.email).thenReturn(tEmail);
      when(() => mockUser.displayName).thenReturn('Test Account');
      when(() => mockUserCredential.user).thenReturn(mockUser);

      when(() => mockFirebaseAuth.signInWithEmailAndPassword(
        email: tEmail,
        password: tPassword,
      )).thenAnswer((_) async => mockUserCredential);

      // Run
      final result = await authService.loginWithEmail(tEmail, tPassword);

      // Assert
      expect(result, isNotNull);
      expect(result?.uid, 'login_uid');
      expect(result?.displayName, 'Test Account');
      
      verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
        email: tEmail,
        password: tPassword,
      )).called(1);
    });

    test('loginWithEmail propagates standard exceptions if firebase rejects', () async {
      // Arrange exception
      when(() => mockFirebaseAuth.signInWithEmailAndPassword(
        email: tEmail,
        password: tPassword,
      )).thenThrow(FirebaseAuthException(code: 'wrong-password', message: 'Incorrect password.'));

      // Act & Assert
      expect(
        () => authService.loginWithEmail(tEmail, tPassword),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
   group('Auth Stream Tests', () {
    test('user stream emits null if no firebase user is signed in', () {
      // Arrange mock stream
      when(() => mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

      // Act & Assert
      expect(authService.user, emitsInOrder([null]));
    });

    test('user stream emits parsed MyUserModel when user log in changes', () {
      // Setup user mock
      when(() => mockUser.uid).thenReturn('auth_change_uid');
      when(() => mockUser.email).thenReturn('new@auth.com');
      when(() => mockUser.displayName).thenReturn('Auth Person');

      when(() => mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

      // Verify values streamed through custom mapping logic
      expect(
        authService.user,
        emits(predicate((dynamic user) {
          return user != null &&
              user.uid == 'auth_change_uid' &&
              user.email == 'new@auth.com';
        })),
      );
    });
  });
  });
}
