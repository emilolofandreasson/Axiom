import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'subject_id_hasher.dart';
import '../sensor/ulid.dart';

// ---------------------------------------------------------------------------
// Phase 1 stub types — replace with real msal_flutter imports in Phase 2
// when wiring up Entra ID interactive sign-in.
// ---------------------------------------------------------------------------

@immutable
class _MsalAuthResult {
  const _MsalAuthResult({
    required this.uniqueId,
    required this.accessToken,
  });
  final String uniqueId;
  final String accessToken;
}

// ---------------------------------------------------------------------------

/// Result returned after a successful sign-in.
@immutable
class FlickIdentity {
  const FlickIdentity({
    required this.subjectId,
    required this.accessToken,
    required this.tenantId,
  });

  /// Anonymized, PII-safe UUID used in all event payloads.
  final String subjectId;

  /// Raw MSAL access token — used for API calls, NEVER stored in events.
  final String accessToken;

  final String tenantId;
}

/// Wraps Microsoft Entra ID (MSAL) to provide a PII-safe [subjectId].
///
/// Phase 1: stubs throw [UnimplementedError] — wire up msal_flutter in Phase 2.
///
/// Usage:
/// ```dart
/// final svc = IdentityService(
///   clientId:    '...',
///   tenantId:    '...',
///   redirectUri: 'msauth.com.example.axiom://auth',
///   hmacSalt:    Env.hmacSalt,
/// );
/// await svc.initialize();
/// final identity = await svc.signIn();
/// EventSensor.instance.setIdentity(identity);
/// ```
class IdentityService {
  IdentityService({
    required String clientId,
    required String tenantId,
    required String redirectUri,
    required String hmacSalt,
    List<String> scopes = const ['User.Read'],
  })  : _clientId    = clientId,
        _tenantId    = tenantId,
        _redirectUri = redirectUri,
        _hmacSalt    = hmacSalt,
        _scopes      = scopes;

  final String _clientId;
  final String _tenantId;
  final String _redirectUri;
  final String _hmacSalt;
  final List<String> _scopes;

  static const _storage        = FlutterSecureStorage();
  static const _kSubjectKey    = 'flick_subject_id';
  static const _kAnonSubjectKey = 'flick_anon_subject_id';

  FlickIdentity? _currentIdentity;
  String?        _persistentAnonSubjectId;

  FlickIdentity? get currentIdentity         => _currentIdentity;
  bool           get isSignedIn              => _currentIdentity != null;
  String?        get persistentAnonSubjectId => _persistentAnonSubjectId;

  Future<void> initialize() async {
    // Phase 2: create PublicClientApplication from msal_flutter here.
    debugPrint(
      '[IdentityService] MSAL not yet wired — clientId=$_clientId  '
      'tenantId=$_tenantId  redirectUri=$_redirectUri  scopes=$_scopes',
    );
    await _trySilentSignIn();
    if (_currentIdentity == null) {
      _persistentAnonSubjectId = await getOrCreateAnonSubjectId();
    }
  }

  /// Interactive sign-in via Entra ID. Opens browser flow.
  Future<FlickIdentity> signIn() async {
    // Phase 2: replace with _msalApp!.acquireToken(scopes: _scopes)
    throw UnimplementedError(
      'IdentityService.signIn — wire up msal_flutter in Phase 2.',
    );
  }

  Future<FlickIdentity?> _trySilentSignIn() async {
    // Phase 2: replace with _msalApp!.acquireTokenSilent(scopes: _scopes)
    final cached = await getCachedSubjectId();
    if (cached != null) {
      _currentIdentity = FlickIdentity(
        subjectId:   cached,
        accessToken: '',
        tenantId:    _tenantId,
      );
    }
    return _currentIdentity;
  }

  Future<void> signOut() async {
    // Phase 2: also call _msalApp?.signOut()
    await _storage.delete(key: _kSubjectKey);
    _currentIdentity = null;
  }

  FlickIdentity _buildIdentity(_MsalAuthResult result) {
    final subjectId = SubjectIdHasher.hash(result.uniqueId, _hmacSalt);

    _currentIdentity = FlickIdentity(
      subjectId:   subjectId,
      accessToken: result.accessToken,
      tenantId:    _tenantId,
    );

    _storage.write(key: _kSubjectKey, value: subjectId);
    return _currentIdentity!;
  }

  /// Returns the cached subject_id from secure storage (no network call).
  Future<String?> getCachedSubjectId() =>
      _storage.read(key: _kSubjectKey);

  /// Returns or creates a persistent anonymous subject ID for pre-auth sessions.
  Future<String> getOrCreateAnonSubjectId() async {
    final existing = await _storage.read(key: _kAnonSubjectKey);
    if (existing != null) return existing;
    final newId = 'anon-${Ulid.generate()}';
    await _storage.write(key: _kAnonSubjectKey, value: newId);
    return newId;
  }
}
