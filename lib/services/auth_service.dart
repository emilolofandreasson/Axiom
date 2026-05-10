import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flick_sdk/flick_sdk.dart';

class AuthService {
  AuthService({required String hmacSalt}) : _hmacSalt = hmacSalt;

  final String _hmacSalt;
  SupabaseClient get _client => Supabase.instance.client;

  void initialize() {
    // Restore existing session immediately if available.
    final user = _client.auth.currentUser;
    if (user != null) _applySubjectId(user);

    _client.auth.onAuthStateChange.listen((state) {
      final user = state.session?.user;
      if (user != null) _applySubjectId(user);
    });
  }

  void _applySubjectId(User user) {
    final hashed = SubjectIdHasher.hash(user.id, _hmacSalt);
    EventSensor.instance.setSubjectIdOverride(hashed);
    debugPrint('[AuthService] subject-id applied for user ${user.id.substring(0, 8)}…');
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> createAccount(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  User? get currentUser => _client.auth.currentUser;

  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((s) => s.session?.user);
}
