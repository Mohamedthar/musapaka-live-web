import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> hasAdmins() async {
    try {
      final result = await _client.rpc('has_admins');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    return _client.auth.currentSession != null;
  }

  Future<void> signInWithPhone(String phone, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: '$phone@admin.com',
      password: password,
    );
    if (response.user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdminLoggedIn', true);
    }
  }

  Future<void> signUp(String phone, String password, String name) async {
    final authResponse = await _client.auth.signUp(
      email: '$phone@admin.com',
      password: password,
    );

    if (authResponse.user != null) {
      await _client.from('admins').insert({
        'id': authResponse.user!.id,
        'name': name,
        'phone': phone,
      });
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAdminLoggedIn');
  }
}
