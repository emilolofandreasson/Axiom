import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  SupabaseClient get _db => Supabase.instance.client;
  final _picker = ImagePicker();

  String? get _uid => _db.auth.currentUser?.id;

  Future<UserProfile?> loadProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final row = await _db
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return UserProfile(uid: uid);
      return UserProfile.fromMap(uid, row);
    } catch (e) {
      debugPrint('[ProfileService] load error: $e');
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .from('users')
          .update(profile.toMap())
          .eq('id', uid);
    } catch (e) {
      debugPrint('[ProfileService] save error: $e');
    }
  }

  Future<String?> pickAndUploadAvatar() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, maxHeight: 512, imageQuality: 85,
      );
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      return _uploadAvatar(uid, bytes);
    } catch (e) {
      debugPrint('[ProfileService] pick error: $e');
      return null;
    }
  }

  Future<String?> _uploadAvatar(String uid, Uint8List bytes) async {
    try {
      final path = '$uid/avatar.jpg';
      await _db.storage.from('axiom').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      final url = _db.storage.from('axiom').getPublicUrl(path);
      await _db.from('users').update({'photo_url': url}).eq('id', uid);
      return url;
    } catch (e) {
      debugPrint('[ProfileService] upload error: $e');
      return null;
    }
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    final uid = _uid;
    if (query.trim().isEmpty) return [];
    try {
      final rows = await _db
          .from('users')
          .select()
          .ilike('name', '${query.trim()}%')
          .limit(10);
      return (rows as List)
          .where((d) => d['id'] != uid)
          .map((d) => UserProfile.fromMap(d['id'] as String, d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProfileService] search error: $e');
      return [];
    }
  }
}
