import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // 1. GET CURRENT USER
  Future<User?> get currentUser async {
    final session = _supabase.auth.currentSession;
    if (session == null || (session.expiresAt != null && DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000).isBefore(DateTime.now()))) {
      await _supabase.auth.refreshSession();
    }
    return _supabase.auth.currentUser;
  }

  // 2. CHECK SESSION (Redirect Logic)
  bool get isLoggedIn => _supabase.auth.currentSession != null;

  // 3. SEND SMS OTP
  // Note: For testing, Supabase allows setting "Fixed OTPs" in Dashboard -> Auth -> Phone
  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
        // In Android/iOS, you need deep links set up for auto-verify,
        // but for manual code entry, this is enough.
      );
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  // 4. VERIFY OTP
  Future<void> verifyOtp(String phone, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        token: token,
        phone: phone,
      );

      // CRITICAL: Once logged in, ensure a Public User Profile exists
      if (response.session != null) {
        await _ensureUserProfile(response.user!);
      }
    } catch (e) {
      throw Exception('Invalid Code: $e');
    }
  }

  // 5. SIGN OUT
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // INTERNAL: Ensure "public.users" row exists
  Future<void> _ensureUserProfile(User user) async {
    final existing = await _supabase.from('users').select().eq('id', user.id).maybeSingle();

    if (existing == null) {
      // New User? Create their public profile
      await _supabase.from('users').insert({
        'id': user.id,
        'phone': user.phone,
        'reputation_score': 50, // Start neutral
        'badges': ['newcomer'], // Welcome Badge
      });
    }
  }
}
