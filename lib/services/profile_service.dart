import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _db      = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth    = FirebaseAuth.instance;
  final _picker  = ImagePicker();

  String? get _uid => _auth.currentUser?.uid;

  Future<UserProfile?> loadProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return UserProfile(uid: uid);
      return UserProfile.fromFirestore(uid, doc.data()!);
    } catch (e) {
      debugPrint('[ProfileService] load error: $e');
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        profile.toFirestore(),
        SetOptions(merge: true),
      );
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
      final ref = _storage.ref('profiles/$uid/avatar.jpg');
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await task.ref.getDownloadURL();
      await _db.collection('users').doc(uid).set(
        {'photoUrl': url}, SetOptions(merge: true));
      return url;
    } catch (e) {
      debugPrint('[ProfileService] upload error: $e');
      return null;
    }
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final snap = await _db
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(10)
          .get();
      return snap.docs
          .where((d) => d.id != _uid)
          .map((d) => UserProfile.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      debugPrint('[ProfileService] search error: $e');
      return [];
    }
  }
}
