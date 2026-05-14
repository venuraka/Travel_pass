import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project/controllers/AuthController.dart';
import 'package:project/controllers/AuthService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/models/UserModel.dart';

class MockAuthService extends Mock implements AuthService {}
class MockBuildContext extends Mock implements BuildContext {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockAuthService mockAuthService;
  late MockBuildContext mockContext;
  late AuthController controller;

  setUp(() {
    mockAuthService = MockAuthService();
    mockContext = MockBuildContext();
    controller = AuthController(authService: mockAuthService);
  });

  group('AuthController Tests', () {
    test('handleSignUp does not call service if passwords mismatch', () async {
      controller.emailController.text = 'test@test.com';
      controller.passwordController.text = 'password123';
      controller.confirmPasswordController.text = 'password456';

      await controller.handleSignUp(mockContext);

      verifyNever(() => mockAuthService.signUpWithEmail(any(), any()));
    });

    test('handleSignUp calls service if passwords match', () async {
      controller.emailController.text = 'test@test.com';
      controller.passwordController.text = 'password123';
      controller.confirmPasswordController.text = 'password123';

      final mockModel = MyUserModel(uid: '123', email: 'test@test.com', displayName: '');
      when(() => mockAuthService.signUpWithEmail('test@test.com', 'password123'))
          .thenAnswer((_) async => mockModel);

      await controller.handleSignUp(mockContext);

      verify(() => mockAuthService.signUpWithEmail('test@test.com', 'password123')).called(1);
    });

    test('handleSignUp handles service exceptions gracefully', () async {
      controller.emailController.text = 'error@test.com';
      controller.passwordController.text = 'password123';
      controller.confirmPasswordController.text = 'password123';

      when(() => mockAuthService.signUpWithEmail('error@test.com', 'password123'))
          .thenThrow(Exception('Signup failed'));

      // Should not throw an unhandled exception
      await controller.handleSignUp(mockContext);

      verify(() => mockAuthService.signUpWithEmail('error@test.com', 'password123')).called(1);
    });
  });
}
