import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/utils/AuthExceptionHandler.dart';

void main() {
  group('AuthExceptionHandler Tests', () {
    test('returns correct message for wrong-password', () {
      final e = FirebaseAuthException(code: 'wrong-password');
      expect(AuthExceptionHandler.handleException(e), 'Wrong password provided.');
    });

    test('returns correct message for user-not-found', () {
      final e = FirebaseAuthException(code: 'user-not-found');
      expect(AuthExceptionHandler.handleException(e), 'No user found for that email.');
    });

    test('returns correct message for email-already-in-use', () {
      final e = FirebaseAuthException(code: 'email-already-in-use');
      expect(AuthExceptionHandler.handleException(e), 'The account already exists for that email.');
    });

    test('returns correct message for invalid-email', () {
      final e = FirebaseAuthException(code: 'invalid-email');
      expect(AuthExceptionHandler.handleException(e), 'The email address is not valid.');
    });

    test('returns correct message for weak-password', () {
      final e = FirebaseAuthException(code: 'weak-password');
      expect(AuthExceptionHandler.handleException(e), 'The password provided is too weak.');
    });

    test('returns correct message for too-many-requests', () {
      final e = FirebaseAuthException(code: 'too-many-requests');
      expect(AuthExceptionHandler.handleException(e), 'Too many requests. Try again later.');
    });

    test('returns correct message for network-request-failed', () {
      final e = FirebaseAuthException(code: 'network-request-failed');
      expect(AuthExceptionHandler.handleException(e), 'Network error. Please check your connection.');
    });

    test('returns correct message for user-disabled', () {
      final e = FirebaseAuthException(code: 'user-disabled');
      expect(AuthExceptionHandler.handleException(e), 'This user has been disabled.');
    });

    test('returns default message for unknown FirebaseAuthException code', () {
      final e = FirebaseAuthException(code: 'unknown-code');
      expect(AuthExceptionHandler.handleException(e), 'User Is not Registerd');
    });

    test('handles Google sign-in cancellation gracefully', () {
      final e = Exception('GoogleSignInException: canceled');
      expect(AuthExceptionHandler.handleException(e), 'Sign in cancelled.');
    });

    test('handles Apple sign-in cancellation gracefully', () {
      final e = Exception('SignInWithAppleAuthorizationException: canceled');
      expect(AuthExceptionHandler.handleException(e), 'Sign in cancelled.');
    });

    test('returns generic fallback for unknown non-Firebase exception', () {
      final e = Exception('Some random error');
      final result = AuthExceptionHandler.handleException(e);
      expect(result, contains('An error occurred'));
    });
  });
}
