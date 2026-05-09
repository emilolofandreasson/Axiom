import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

enum FriendRequestStatus { pending, accepted, declined }

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromPhotoUrl,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });

  final String              id;
  final String              fromUid;
  final String              fromName;
  final String?             fromPhotoUrl;
  final String              toUid;
  final FriendRequestStatus status;
  final DateTime            createdAt;

  factory FriendRequest.fromFirestore(String id, Map<String, dynamic> d) =>
      FriendRequest(
        id:           id,
        fromUid:      d['fromUid']      as String,
        fromName:     d['fromName']     as String? ?? 'Unknown',
        fromPhotoUrl: d['fromPhotoUrl'] as String?,
        toUid:        d['toUid']        as String,
        status: FriendRequestStatus.values.firstWhere(
          (s) => s.name == (d['status'] as String? ?? 'pending'),
          orElse: () => FriendRequestStatus.pending,
        ),
        createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class FriendService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> sendRequest(UserProfile to, UserProfile from) async {
    final uid = _uid;
    if (uid == null) return;

    final existing = await _db
        .collection('friendRequests')
        .where('fromUid', isEqualTo: uid)
        .where('toUid', isEqualTo: to.uid)
        .get();
    if (existing.docs.isNotEmpty) return; // already sent

    try {
      await _db.collection('friendRequests').add({
        'fromUid':      uid,
        'fromName':     from.name,
        'fromPhotoUrl': from.photoUrl,
        'toUid':        to.uid,
        'status':       'pending',
        'createdAt':    FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FriendService] sendRequest error: $e');
    }
  }

  Future<void> acceptRequest(FriendRequest req) async {
    try {
      final batch = _db.batch();

      batch.update(_db.collection('friendRequests').doc(req.id), {
        'status': 'accepted',
      });

      // Add both directions to friends subcollections.
      batch.set(
        _db.collection('users').doc(req.toUid).collection('friends').doc(req.fromUid),
        {'addedAt': FieldValue.serverTimestamp()},
      );
      batch.set(
        _db.collection('users').doc(req.fromUid).collection('friends').doc(req.toUid),
        {'addedAt': FieldValue.serverTimestamp()},
      );

      await batch.commit();
    } catch (e) {
      debugPrint('[FriendService] acceptRequest error: $e');
    }
  }

  Future<void> declineRequest(FriendRequest req) async {
    try {
      await _db.collection('friendRequests').doc(req.id).update({
        'status': 'declined',
      });
    } catch (e) {
      debugPrint('[FriendService] declineRequest error: $e');
    }
  }

  Future<void> removeFriend(String friendUid) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(uid).collection('friends').doc(friendUid));
      batch.delete(_db.collection('users').doc(friendUid).collection('friends').doc(uid));
      await batch.commit();
    } catch (e) {
      debugPrint('[FriendService] removeFriend error: $e');
    }
  }

  Stream<List<FriendRequest>> incomingRequests() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('friendRequests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs
            .map((d) => FriendRequest.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<List<UserProfile>> friendsList() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('friends')
          .get();

      final profiles = await Future.wait(
        snap.docs.map((d) async {
          final userDoc = await _db.collection('users').doc(d.id).get();
          return UserProfile.fromFirestore(
              d.id, userDoc.data() ?? {});
        }),
      );
      return profiles;
    } catch (e) {
      debugPrint('[FriendService] friendsList error: $e');
      return [];
    }
  }

  Future<bool> isFriend(String otherUid) async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _db
        .collection('users').doc(uid)
        .collection('friends').doc(otherUid)
        .get();
    return doc.exists;
  }
}
