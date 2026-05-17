import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient supabase;

  Future<void> init(String url, String anonKey) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    supabase = Supabase.instance.client;
    print('✅ Supabase initialized');
  }

  // ================= SIGN UP =================
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Save extra user info in "users" table
        await supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'name': name,
        });

        await saveLoginState(true);
        return {'success': true, 'user': response.user};
      } else {
        return {'error': 'Sign-up failed'};
      }
    } on AuthException catch (e) {
      print('❌ Auth error in signUp: ${e.message}');
      return {'error': e.message};
    } catch (e) {
      print('❌ General error in signUp: $e');
      return {'error': e.toString()};
    }
  }

  // ================= SIGN IN =================
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await saveLoginState(true);
        return {'success': true, 'user': response.user};
      } else {
        return {'error': 'Invalid email or password'};
      }
    } on AuthException catch (e) {
      print('❌ Auth error in signIn: ${e.message}');
      return {'error': e.message};
    } catch (e) {
      print('❌ General error in signIn: $e');
      return {'error': e.toString()};
    }
  }

  // ================= LOGIN STATE =================
  Future<void> saveLoginState(bool loggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', loggedIn);
  }

  Future<bool> getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}
