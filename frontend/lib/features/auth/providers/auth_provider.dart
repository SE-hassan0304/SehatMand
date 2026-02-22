// lib/features/auth/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import 'firebase_auth_stream_provider.dart';

// Re-export so anything that previously imported auth_provider.dart
// still gets firebaseAuthStreamProvider for free.
export 'firebase_auth_stream_provider.dart';

// ── Derived: current UserModel ───────────────────────────────────────────────
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(firebaseAuthStreamProvider).maybeWhen(
        data: (User? firebaseUser) {
          if (firebaseUser == null) return null;
          return UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ??
                firebaseUser.email?.split('@').first ??
                'User',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
          );
        },
        orElse: () => null,
      );
});

// ── Auth State (loading / error feedback only) ───────────────────────────────
class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result =
        await AuthService.signUp(name: name, email: email, password: password);
    if (result['success'] == true) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result['error']);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await AuthService.login(email: email, password: password);
    if (result['success'] == true) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result['error']);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await AuthService.signInWithGoogle();
    if (result['success'] == true) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result['error']);
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
