import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<AuthResponse> signUp({required String email, required String password});
  Future<AuthResponse> signUpWithProfile({
    required String email,
    required String password,
    required String displayName,
    String? referralSource,
  });
  Future<AuthResponse> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> resetPassword(String email);
  User? getCurrentUser();
  Stream<AuthState> get authStateChanges;
}

