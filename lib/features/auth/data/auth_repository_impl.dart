import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final _client = SupabaseService.client;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<AuthResponse> signUpWithProfile({
    required String email,
    required String password,
    required String displayName,
    String? referralSource,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        'referral_source': referralSource ?? '',
      },
    );
    // Profil in user_profiles anlegen (Tabelle aus Migration 14)
    if (response.user != null) {
      try {
        await _client.from('user_profiles').upsert({
          'id': response.user!.id,
          'display_name': displayName,
          'referral_source': referralSource ?? '',
        });
      } catch (_) {}
    }
    return response;
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  User? getCurrentUser() => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}




