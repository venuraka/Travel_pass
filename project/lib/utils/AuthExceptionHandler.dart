import 'package:firebase_auth/firebase_auth.dart';

class AuthExceptionHandler {
  static String handleException(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'The account already exists for that email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'operation-not-allowed':
          return 'Operation not allowed. Please contact support.';
        case 'user-disabled':
          return 'This user has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'credential-already-in-use':
          return 'This credential is already associated with a different user account.';
        default:
          return 'Authentication failed: ${e.message ?? "Unknown error"}';
      }
    } else {
      return 'An error occurred: ${e.toString()}';
    }
  }
}
