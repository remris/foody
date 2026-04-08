import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kokomi/features/auth/data/auth_repository_impl.dart';
import 'package:kokomi/features/auth/domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// Auth-State: null = loading, User = eingeloggt, AuthException = ausgeloggt
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  // Sofort den aktuellen User aus Supabase lesen (Session-Persistenz)
  // authStateProvider braucht einen Moment bis der Stream feuert –
  // in der Zwischenzeit nutzen wir den bereits geladenen User direkt.
  return authState.whenOrNull(
        data: (state) => state.session?.user,
      ) ??
      Supabase.instance.client.auth.currentUser;
});

// Notifier für Sign-In / Sign-Up Aktionen
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password);
    });
  }

  Future<void> signUpWithProfile({
    required String email,
    required String password,
    required String displayName,
    String? referralSource,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signUpWithProfile(
            email: email,
            password: password,
            displayName: displayName,
            referralSource: referralSource,
          );
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).resetPassword(email);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);

