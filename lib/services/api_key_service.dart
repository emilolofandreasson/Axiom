import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../config/env.dart';
import '../main.dart' show lessonGenerator;
import '../services/lesson_generator.dart';

class ApiKeyService {
  static const _storage = FlutterSecureStorage();
  static const _kKey    = 'gemini_api_key';

  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid      => _db.auth.currentUser?.id;

  Future<String?> loadKey() => _storage.read(key: _kKey);

  Future<bool> saveKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty || !_verify(trimmed)) return false;

    await _storage.write(key: _kKey, value: trimmed);
    await _syncToSupabase(trimmed);
    _applyToGenerator(trimmed);
    return true;
  }

  Future<void> clearKey() async {
    await _storage.delete(key: _kKey);
    _applyToGenerator(null);
  }

  Future<void> initFromStorage() async {
    final key = await loadKey();
    if (key != null && key.isNotEmpty) {
      _applyToGenerator(key);
    }
  }

  Future<void> syncFromSupabase() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final row = await _db
          .from('users')
          .select('gemini_key')
          .eq('id', uid)
          .maybeSingle();

      final key = row?['gemini_key'] as String?;
      if (key != null && key.isNotEmpty) {
        await _storage.write(key: _kKey, value: key);
        _applyToGenerator(key);
        debugPrint('[ApiKeyService] loaded key from Supabase');
      }
    } catch (e) {
      debugPrint('[ApiKeyService] Supabase sync failed: $e');
    }
  }

  bool _verify(String key) =>
      key.startsWith('AIzaSy') && key.length >= 35;

  Future<void> _syncToSupabase(String key) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      await _db
          .from('users')
          .update({'gemini_key': key})
          .eq('id', uid);
    } catch (e) {
      debugPrint('[ApiKeyService] Supabase write failed: $e');
    }
  }

  void _applyToGenerator(String? key) {
    final proxyUrl = Env.proxyUrl.isNotEmpty ? Env.proxyUrl : null;
    final EdgeAiBridge bridge;
    if (key != null && key.isNotEmpty) {
      bridge = GeminiBridge(apiKey: key, proxyUrl: proxyUrl);
    } else if (proxyUrl != null) {
      bridge = GeminiBridge(apiKey: '', proxyUrl: proxyUrl);
    } else {
      bridge = StubEdgeAiBridge();
    }
    bridge.loadModel('');
    lessonGenerator = LessonGenerator(bridge: bridge);
    debugPrint('[ApiKeyService] generator updated — '
        '${bridge is GeminiBridge ? "GeminiBridge(${key?.isNotEmpty == true ? "user-key" : "server-key"})" : "StubBridge"}');
  }
}
