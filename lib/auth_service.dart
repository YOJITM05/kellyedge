import 'package:firebase_auth/firebase_auth.dart';

// =========================================================
// AUTH LAYER
// Thin wrapper around FirebaseAuth so the UI never talks to
// the Firebase SDK directly. One place owns the logic,
// everything else just reads its output.
// =========================================================
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Live sign-in state as a stream, so AuthGate can react to
  // it without polling.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return _friendlyMessage(e.code);
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyMessage(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Maps Firebase's error codes to plain-English messages, in the
  // same style as the calculator's own validation messages.
  String _friendlyMessage(String code) {
    if (code == 'email-already-in-use') {
      return 'An account already exists for that email.';
    } else if (code == 'invalid-email') {
      return 'That email address looks invalid.';
    } else if (code == 'weak-password') {
      return 'Password must be at least 6 characters.';
    } else if (code == 'user-not-found' ||
        code == 'wrong-password' ||
        code == 'invalid-credential') {
      return 'Incorrect email or password.';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }
}
