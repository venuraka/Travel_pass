import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/UserModel.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  /// Ensures GoogleSignIn is initialized before use.
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
  }

  // 1. Auth Change User Stream
  Stream<MyUserModel?> get user {
    return _auth.authStateChanges().map((User? user) {
      return user != null ? MyUserModel.fromFirebaseUser(user) : null;
    });
  }

  // 2. Sign Up with Email and Password
  Future<MyUserModel?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return MyUserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      rethrow;
    }
  }

  // 3. Login with Email and Password
  Future<MyUserModel?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return MyUserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      rethrow;
    }
  }

  // 4. Sign in with Google
  Future<MyUserModel?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details (v7 only provides idToken here)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      UserCredential result = await _auth.signInWithCredential(credential);
      return MyUserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      rethrow;
    }
  }

  // 5. Delete Account with Re-authentication
  Future<void> deleteAccountWithReauth({String? password}) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      AuthCredential? credential;

      // Check which provider the user is using for re-authentication
      for (UserInfo userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com') {
          await _ensureInitialized();
          final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
          if (googleUser != null) {
            final GoogleSignInAuthentication googleAuth =
                await googleUser.authentication;
            credential = GoogleAuthProvider.credential(
              idToken: googleAuth.idToken,
            );
          }
        } else if (userInfo.providerId == 'password' && password != null) {
          credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
        }
      }

      // 1. Re-authenticate if we got a credential
      if (credential != null) {
        await user.reauthenticateWithCredential(credential);
      } else if (password == null &&
          !user.providerData.any((p) => p.providerId == 'google.com')) {
        throw Exception("Password required for email re-authentication.");
      }

      // 2. Perform deletion
      await user.delete();
    } catch (e) {
      rethrow;
    }
  }
}
