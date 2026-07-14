import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> registerWithEmailAndPassword(String email, String password) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password);
    } catch (e) {
      throw Exception("Erro ao cadastrar: $e");
    }
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception("Erro ao fazer login: $e");
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception("Erro ao deslogar: $e");
    }
  }

  String? currentUser() {
    return _supabase.auth.currentUser?.id;
  }
}
