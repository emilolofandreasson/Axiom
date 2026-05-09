import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../main.dart' show lessonGenerator;
import '../services/lesson_generator.dart';

class ApiKeyService {
  static const _storage = FlutterSecureStorage();
  static const _kKey    = 'gemini_api_key';

  Future<String?> loadKey() => _storage.read(key: _kKey);

  Future<bool> saveKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;

    final valid = await _verify(trimmed);
    if (!valid) return false;

    await _storage.write(key: _kKey, value: trimmed);
    await _syncToFirestore(trimmed);
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

  Future<void> syncFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final key = doc.data()?['gemini_key'] as String?;
      if (key != null && key.isNotEmpty) {
        await _storage.write(key: _kKey, value: key);
        _applyToGenerator(key);
        debugPrint('[ApiKeyService] loaded key from Firestore');
      }
    } catch (e) {
      debugPrint('[ApiKeyService] Firestore sync failed: $e');
    }
  }

  Future<bool> _verify(String key) async {
    try {
      final bridge = GeminiBridge(apiKey: key);
      await bridge.loadModel('');
      final result = await bridge.complete(const InferenceRequest(
        prompt:    'Say "ok" in JSON: {"status":"ok"}',
        maxTokens: 20,
      ));
      return result.isSuccess;
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncToFirestore(String key) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'gemini_key': key}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[ApiKeyService] Firestore write failed: $e');
    }
  }

  void _applyToGenerator(String? key) {
    final bridge = (key != null && key.isNotEmpty)
        ? GeminiBridge(apiKey: key)
        : StubEdgeAiBridge();
    bridge.loadModel('');
    lessonGenerator = LessonGenerator(bridge: bridge);
    debugPrint('[ApiKeyService] generator updated — '
        '${key != null ? "GeminiBridge" : "StubBridge"}');
  }
}
