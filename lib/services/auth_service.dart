import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flick_sdk/flick_sdk.dart';

class AuthService {
  AuthService({required String hmacSalt}) : _hmacSalt = hmacSalt;

  final String _hmacSalt;
  static const _storage   = FlutterSecureStorage();
  static const _kAnonKey  = 'flick_anon_subject_id';

  final _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    final user = _auth.currentUser ?? await _signInAnonymously();
    _applySubjectId(user);

    _auth.authStateChanges().listen((user) {
      if (user != null) _applySubjectId(user);
    });
  }

  Future<User> _signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  void _applySubjectId(User user) {
    final raw = user.isAnonymous
        ? 'anon-${user.uid.substring(0, 12)}'
        : SubjectIdHasher.hash(user.uid, _hmacSalt);
    EventSensor.instance.setSubjectIdOverride(raw);
  }

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> createAccount(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;
  bool  get isAnonymous  => _auth.currentUser?.isAnonymous ?? true;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
