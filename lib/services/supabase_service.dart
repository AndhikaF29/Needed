import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase client
  final supabase = Supabase.instance.client;

  // Auth methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Cek apakah email sudah terdaftar
      final data = await supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (data != null) {
        throw 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      }

      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        throw 'Pendaftaran gagal: User tidak ditemukan';
      }

      await supabase.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
      });

      return response;
    } on AuthException catch (error) {
      if (error.message.contains('User already registered')) {
        throw 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      }
      throw error.message;
    } catch (error) {
      print('Error: $error');
      throw 'Terjadi kesalahan saat pendaftaran: $error';
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Cek email terlebih dahulu
      final userData = await supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();
      
      if (userData == null) {
        throw 'Email belum terdaftar. Silakan daftar terlebih dahulu.';
      }

      try {
        final AuthResponse response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user == null) {
          throw 'Login gagal: Email atau password salah';
        }

        return response;
      } on AuthException catch (error) {
        if (error.message.contains('Invalid login credentials')) {
          throw 'Email atau password yang Anda masukkan salah';
        }
        throw 'Gagal login: ${error.message}';
      }
    } catch (error) {
      // Teruskan error yang sudah diformat sebelumnya
      if (error is String) {
        throw error;
      }
      // Untuk error yang tidak terduga
      throw 'Terjadi kesalahan saat login. Silakan coba lagi.';
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Profile methods
  Future<void> _createProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    await supabase.from('profiles').insert({
      'id': userId,
      'name': name,
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response =
        await supabase.from('profiles').select().eq('id', userId).single();
    return response;
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    final updates = {
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await supabase.from('profiles').update(updates).eq('id', userId);
  }

  // Check if user is logged in
  bool get isAuthenticated => supabase.auth.currentUser != null;

  // Get current user
  User? get currentUser => supabase.auth.currentUser;
}
