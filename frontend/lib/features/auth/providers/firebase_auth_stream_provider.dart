// lib/features/auth/providers/firebase_auth_stream_provider.dart
//
// Isolated here so app_router, splash_screen, and auth_screen can all import
// this single file without any risk of circular dependency.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth for Firebase auth state.
/// Automatically persists across app restarts.
final firebaseAuthStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
