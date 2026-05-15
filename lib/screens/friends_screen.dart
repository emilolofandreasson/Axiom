import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/friend_service.dart';
import '../services/profile_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.myProfile});
  final UserProfile myProfile;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _friendService  = FriendService();
  final _profileService = ProfileService();
  final _searchCtrl     = TextEditingController();

  List<UserProfile>  _friends  = [];
  List<UserProfile>  _results  = [];
  bool _searchLoading = false;

  List<UserProfile> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadFriends();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final list = await _friendService.friendsList();
    if (mounted) setState(() => _friends = list);
  }

  Future<void> _loadLeaderboard() async {
    final list = await _friendService.leaderboard();
    if (mounted) setState(() => _leaderboard = list);
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searchLoading = true);
    final r = await _profileService.searchUsers(q.trim());
    if (mounted) setState(() { _results = r; _searchLoading = false; });
  }

  Future<void> _sendRequest(UserProfile to) async {
    final ok = await _friendService.sendRequest(to, widget.myProfile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Request sent to ${to.name.isNotEmpty ? to.name : 'user'} ✓'
          : 'Could not send request — already sent or an error occurred.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Requests'),
            Tab(text: 'Find'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _FriendsList(
            friends:       _friends,
            friendService: _friendService,
            onRemoved:     _loadFriends,
          ),
          _LeaderboardTab(
            entries:      _leaderboard,
            myUid:        widget.myProfile.uid,
            onRefresh:    _loadLeaderboard,
          ),
          _RequestsList(
            friendService: _friendService,
            onAccepted:    _loadFriends,
          ),
          _FindTab(
            ctrl:          _searchCtrl,
            results:       _results,
            loading:       _searchLoading,
            onSearch:      _search,
            onAdd:         _sendRequest,
            friendService: _friendService,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _FriendsList extends StatelessWidget {
  const _FriendsList({
    required this.friends,
    required this.friendService,
    required this.onRemoved,
  });
  final List<UserProfile> friends;
  final FriendService     friendService;
  final VoidCallback      onRemoved;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const Center(
        child: Text('No friends yet — find someone in the Find tab.',
            style: TextStyle(color: FlickColors.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(FlickSpacing.lg),
      itemCount: friends.length,
      itemBuilder: (_, i) => _UserTile(
        profile: friends[i],
        trailing: TextButton(
          style: TextButton.styleFrom(foregroundColor: FlickColors.error),
          onPressed: () async {
            await friendService.removeFriend(friends[i].uid);
            onRemoved();
          },
          child: const Text('Remove'),
        ),
      ).animate(delay: (i * 40).ms).fadeIn(),
    );
  }
}

// ---------------------------------------------------------------------------

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({
    required this.entries,
    required this.myUid,
    required this.onRefresh,
  });

  final List<UserProfile> entries;
  final String            myUid;
  final VoidCallback      onRefresh;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Add friends to see the leaderboard',
                style: Theme.of(context).textTheme.bodyLarge!
                    .copyWith(color: FlickColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(FlickSpacing.lg),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final entry   = entries[i];
          final isMe    = entry.uid == myUid;
          final medal   = i < 3 ? _medals[i] : '${i + 1}.';
          final name    = entry.name.isNotEmpty ? entry.name : 'Player';

          return Container(
            margin: const EdgeInsets.only(bottom: FlickSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: FlickSpacing.md,
              vertical:   FlickSpacing.md - 2,
            ),
            decoration: BoxDecoration(
              color: isMe
                  ? FlickColors.primaryDim
                  : FlickColors.surface,
              borderRadius: const BorderRadius.all(FlickRadius.lg),
              border: Border.all(
                color: isMe ? FlickColors.primary : FlickColors.border,
                width: isMe ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    medal,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: FlickSpacing.sm),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: FlickColors.surfaceDim,
                  backgroundImage: entry.photoUrl != null
                      ? NetworkImage(entry.photoUrl!)
                      : null,
                  child: entry.photoUrl == null
                      ? Text(name[0].toUpperCase(),
                          style: const TextStyle(
                              color: FlickColors.textSecondary,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: FlickSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? '$name (you)' : name,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: isMe
                                  ? FlickColors.primary
                                  : FlickColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.streakCount > 0)
                        Text('🔥 ${entry.streakCount} day streak',
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(color: FlickColors.textMuted)),
                    ],
                  ),
                ),
                Text(
                  '${entry.totalXp} XP',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: isMe ? FlickColors.primary : FlickColors.textSecondary),
                ),
              ],
            ),
          ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.04);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _RequestsList extends StatelessWidget {
  const _RequestsList({
    required this.friendService,
    required this.onAccepted,
  });
  final FriendService friendService;
  final VoidCallback  onAccepted;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FriendRequest>>(
      stream: friendService.incomingRequests(),
      builder: (context, snap) {
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Text('No pending requests.',
                style: TextStyle(color: FlickColors.textMuted)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(FlickSpacing.lg),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final req = requests[i];
            return _UserTile(
              profile: UserProfile(
                  uid: req.fromUid,
                  name: req.fromName,
                  photoUrl: req.fromPhotoUrl),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      await friendService.acceptRequest(req);
                      onAccepted();
                    },
                    child: const Text('Accept'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: FlickColors.error),
                    onPressed: () => friendService.declineRequest(req),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ).animate(delay: (i * 40).ms).fadeIn();
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _FindTab extends StatelessWidget {
  const _FindTab({
    required this.ctrl,
    required this.results,
    required this.loading,
    required this.onSearch,
    required this.onAdd,
    required this.friendService,
  });
  final TextEditingController ctrl;
  final List<UserProfile>     results;
  final bool                  loading;
  final ValueChanged<String>  onSearch;
  final ValueChanged<UserProfile> onAdd;
  final FriendService         friendService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(FlickSpacing.lg),
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Search by name…',
              prefixIcon: Icon(Icons.search_rounded,
                  color: FlickColors.textMuted, size: 20),
            ),
            onChanged: onSearch,
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(FlickSpacing.lg),
            child: CircularProgressIndicator(),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: FlickSpacing.lg),
              itemCount: results.length,
              itemBuilder: (_, i) => _UserTile(
                profile: results[i],
                trailing: TextButton(
                  onPressed: () => onAdd(results[i]),
                  child: const Text('Add'),
                ),
              ).animate(delay: (i * 40).ms).fadeIn(),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _UserTile extends StatelessWidget {
  const _UserTile({required this.profile, required this.trailing});
  final UserProfile profile;
  final Widget      trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: FlickSpacing.sm),
      padding: const EdgeInsets.all(FlickSpacing.md),
      decoration: BoxDecoration(
        color:        FlickColors.surface,
        borderRadius: const BorderRadius.all(FlickRadius.lg),
        border:       Border.all(color: FlickColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: FlickColors.primaryDim,
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? const Icon(Icons.person_rounded,
                    size: 20, color: FlickColors.primary)
                : null,
          ),
          const SizedBox(width: FlickSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? 'Unnamed' : profile.name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (profile.bio.isNotEmpty)
                  Text(profile.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
