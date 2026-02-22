import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Required for web — must match your OAuth Web Client ID in index.html
    clientId: kIsWeb
        ? '1090255903778-1p2evqimqi53vdvjhpaqcnl5k13s3pmd.apps.googleusercontent.com'
        : null,
  );

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign up ──────────────────────────────────────────────────────
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
      await result.user?.reload();
      return {'success': true, 'user': _auth.currentUser};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Something went wrong. Please try again.'
      };
    }
  }

  // ── Login ────────────────────────────────────────────────────────
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
    } catch (e) {
      return {
        'success': false,
        'error': 'Something went wrong. Please try again.'
      };
    }
  }

  // ── Google Sign In ───────────────────────────────────────────────
  // On web, GoogleSignIn.signIn() does NOT work — must use signInWithPopup.
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      UserCredential result;

      if (kIsWeb) {
        // Web: Firebase popup flow (required — google_sign_in doesn't work on web)
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        result = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile: google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return {'success': false, 'error': 'Google sign-in was cancelled.'};
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        result = await _auth.signInWithCredential(credential);
      }

      return {'success': true, 'user': result.user};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') {
        return {'success': false, 'error': 'Google sign-in was cancelled.'};
      }
      return {'success': false, 'error': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Google sign-in failed. Please try again.'
      };
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  static Future<void> logout() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Error messages (English) ─────────────────────────────────────
  static String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'popup-blocked':
        return 'Pop-up blocked by browser. Please allow pop-ups for this site.';
      case 'cancelled-popup-request':
        return 'Sign-in was cancelled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
