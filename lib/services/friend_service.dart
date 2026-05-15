import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  factory FriendRequest.fromMap(Map<String, dynamic> d) => FriendRequest(
    id:           d['id']            as String,
    fromUid:      d['from_uid']      as String,
    fromName:     d['from_name']     as String? ?? 'Unknown',
    fromPhotoUrl: d['from_photo_url'] as String?,
    toUid:        d['to_uid']        as String,
    status: FriendRequestStatus.values.firstWhere(
      (s) => s.name == (d['status'] as String? ?? 'pending'),
      orElse: () => FriendRequestStatus.pending,
    ),
    createdAt: DateTime.parse(d['created_at'] as String),
  );
}

class FriendService {
  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid       => _db.auth.currentUser?.id;

  Future<bool> sendRequest(UserProfile to, UserProfile from) async {
    final uid = _uid;
    if (uid == null) return false;

    // Prevent duplicates.
    try {
      final existing = await _db
          .from('friend_requests')
          .select()
          .eq('from_uid', uid)
          .eq('to_uid', to.uid)
          .maybeSingle();
      if (existing != null) return false;

      await _db.from('friend_requests').insert({
        'from_uid':       uid,
        'from_name':      from.name.isNotEmpty ? from.name : 'User',
        'from_photo_url': from.photoUrl,
        'to_uid':         to.uid,
        'status':         'pending',
      });
      return true;
    } catch (e) {
      debugPrint('[FriendService] sendRequest error: $e');
      return false;
    }
  }

  Future<void> acceptRequest(FriendRequest req) async {
    try {
      await _db
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('id', req.id);

      // Add both directions to user_friends.
      await _db.from('user_friends').insert([
        {'user_id': req.toUid,   'friend_id': req.fromUid},
        {'user_id': req.fromUid, 'friend_id': req.toUid},
      ]);
    } catch (e) {
      debugPrint('[FriendService] acceptRequest error: $e');
    }
  }

  Future<void> declineRequest(FriendRequest req) async {
    try {
      await _db
          .from('friend_requests')
          .update({'status': 'declined'})
          .eq('id', req.id);
    } catch (e) {
      debugPrint('[FriendService] declineRequest error: $e');
    }
  }

  Future<void> removeFriend(String friendUid) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .from('user_friends')
          .delete()
          .or('and(user_id.eq.$uid,friend_id.eq.$friendUid),and(user_id.eq.$friendUid,friend_id.eq.$uid)');
    } catch (e) {
      debugPrint('[FriendService] removeFriend error: $e');
    }
  }

  Stream<List<FriendRequest>> incomingRequests() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .from('friend_requests')
        .stream(primaryKey: ['id'])
        .eq('to_uid', uid)
        .map((rows) => rows
            .where((d) => d['status'] == 'pending')
            .map((d) => FriendRequest.fromMap(d))
            .toList());
  }

  Future<List<UserProfile>> friendsList() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final friendRows = await _db
          .from('user_friends')
          .select('friend_id')
          .eq('user_id', uid);

      final ids = (friendRows as List)
          .map((r) => r['friend_id'] as String)
          .toList();
      if (ids.isEmpty) return [];

      final userRows = await _db
          .from('users')
          .select()
          .inFilter('id', ids);

      return (userRows as List)
          .map((d) => UserProfile.fromMap(d['id'] as String, d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[FriendService] friendsList error: $e');
      return [];
    }
  }

  /// Returns friends + self, sorted by total_xp descending.
  Future<List<UserProfile>> leaderboard() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final friendRows = await _db
          .from('user_friends')
          .select('friend_id')
          .eq('user_id', uid);

      final friendIds = (friendRows as List)
          .map((r) => r['friend_id'] as String)
          .toList();

      final allIds = [uid, ...friendIds];
      final userRows = await _db
          .from('users')
          .select('id, name, photo_url, total_xp, streak_count')
          .inFilter('id', allIds)
          .order('total_xp', ascending: false);

      return (userRows as List)
          .map((d) => UserProfile.fromMap(d['id'] as String, d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[FriendService] leaderboard error: $e');
      return [];
    }
  }

  Future<bool> isFriend(String otherUid) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _db
        .from('user_friends')
        .select()
        .eq('user_id', uid)
        .eq('friend_id', otherUid)
        .maybeSingle();
    return row != null;
  }
}
