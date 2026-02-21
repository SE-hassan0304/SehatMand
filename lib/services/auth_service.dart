import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Get current logged in user ───────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign up with email & password ────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(name);
      return {'success': true, 'user': result.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getErrorMessage(e.code)};
    }
  }

  // ── Login with email & password ──────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {'success': true, 'user': result.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getErrorMessage(e.code)};
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Firebase error messages in simple Urdu/English ──────────────
  static String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Yeh email pehle se registered hai.';
      case 'invalid-email':
        return 'Email address sahi nahi hai.';
      case 'weak-password':
        return 'Password kam az kam 6 characters ka hona chahiye.';
      case 'user-not-found':
        return 'Yeh email registered nahi hai.';
      case 'wrong-password':
        return 'Password galat hai.';
      default:
        return 'Kuch masla aa gaya. Dobara try karein.';
    }
  }
}
