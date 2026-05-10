import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/language.dart';
import '../models/language_level.dart';
import '../models/puzzle_level.dart';
import '../models/user_profile.dart';
import '../providers/language_provider.dart';
import '../providers/saga_provider.dart';
import '../main.dart' show authService, apiKeyService;
import '../services/profile_service.dart';
import 'api_key_screen.dart';
import 'debug_screen.dart';
import 'edit_profile_screen.dart';
import 'friends_screen.dart';
import 'privacy_settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProfile? _profile;
  final _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _profileService.loadProfile();
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final saga     = ref.watch(sagaProvider);
    final language = ref.watch(languageProvider);

    final completedCount = saga.completedIds.length;
    final langXp         = saga.xpForLanguage(language.code);
    final level          = levelForXp(langXp);
    // progress within the current sub-level (0.0 – 1.0)
    final xpProgress     = level.isMax
        ? 1.0
        : level.progressFraction(langXp).clamp(0.02, 1.0); // min sliver so bar is visible

    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (authService.currentUser != null)
            TextButton(
              onPressed: _profile == null ? null : () async {
                final updated = await Navigator.push<UserProfile>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(profile: _profile!),
                  ),
                );
                if (updated != null) setState(() => _profile = updated);
              },
              child: const Text('Edit'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FlickSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Identity card
            _SectionCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: FlickColors.primaryDim,
                        backgroundImage: _profile?.photoUrl != null
                            ? NetworkImage(_profile!.photoUrl!)
                            : null,
                        child: _profile?.photoUrl == null
                            ? const Icon(Icons.person_rounded,
                                color: FlickColors.primary, size: 28)
                            : null,
                      ),
                      const SizedBox(width: FlickSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile?.name.isNotEmpty == true
                                  ? _profile!.name
                                  : (authService.currentUser?.email ?? 'Learner'),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _profile?.bio.isNotEmpty == true
                                  ? _profile!.bio
                                  : 'Tap Edit to add a bio',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FlickSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FriendsScreen(
                              myProfile: _profile ??
                                  UserProfile(
                                    uid: authService.currentUser?.id ?? '',
                                  )),
                        ),
                      ),
                      icon: const Icon(Icons.people_rounded, size: 18),
                      label: const Text('Friends'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FlickColors.primary,
                        side: const BorderSide(color: FlickColors.border),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(FlickRadius.full),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: FlickSpacing.lg),

            Text('Progress',
                style: Theme.of(context).textTheme.headlineSmall)
                .animate().fadeIn(delay: 80.ms),

            const SizedBox(height: FlickSpacing.md),

            // XP progress
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: FlickSpacing.sm),
                      Text('${langXp} XP',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(width: FlickSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlickSpacing.sm,
                          vertical: FlickSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: FlickColors.primaryDim,
                          borderRadius: const BorderRadius.all(FlickRadius.full),
                        ),
                        child: Text(level.label,
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(color: FlickColors.primary)),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          level.isMax
                              ? 'Max level 🏆'
                              : '${level.xpToNextLevel(langXp)} XP to next level',
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FlickSpacing.sm),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: xpProgress),
                    duration: 800.ms,
                    curve: Curves.easeOut,
                    builder: (_, value, __) => LinearProgressIndicator(
                      value:           value,
                      backgroundColor: FlickColors.surfaceDim,
                      valueColor: AlwaysStoppedAnimation(
                          level.isMax ? FlickColors.success : FlickColors.primary),
                      borderRadius:
                          const BorderRadius.all(FlickRadius.full),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 120.ms),

            const SizedBox(height: FlickSpacing.md),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon:  '🔥',
                    value: '${saga.streakCount}',
                    label: 'Day streak',
                  ),
                ),
                const SizedBox(width: FlickSpacing.md),
                Expanded(
                  child: _StatCard(
                    icon:  '🧩',
                    value: '$completedCount',
                    label: 'Levels done',
                  ),
                ),
                const SizedBox(width: FlickSpacing.md),
                Expanded(
                  child: _StatCard(
                    icon:  '👁',
                    value: '${saga.revealPowerups}',
                    label: 'Powerups',
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 160.ms),

            const SizedBox(height: FlickSpacing.lg),

            Text('Languages',
                style: Theme.of(context).textTheme.headlineSmall)
                .animate().fadeIn(delay: 200.ms),

            const SizedBox(height: FlickSpacing.md),

            ...kLanguages
                .where((l) => l.hasContent)
                .toList()
                .asMap()
                .entries
                .map((e) {
              final lang   = e.value;
              final levels = kPuzzleLevelsByLanguage[lang.code] ?? [];
              final done   = levels
                  .where((l) => saga.isCompleted(l.id))
                  .length;
              final isActive = language.code == lang.code;

              return Padding(
                padding: const EdgeInsets.only(bottom: FlickSpacing.sm),
                child: _LanguageProgressCard(
                  language:    lang,
                  done:        done,
                  total:       levels.length,
                  isActive:    isActive,
                ).animate().fadeIn(delay: Duration(milliseconds: 220 + e.key * 60)),
              );
            }),

            const SizedBox(height: FlickSpacing.lg),

            Text('AI Tutor',
                style: Theme.of(context).textTheme.headlineSmall)
                .animate().fadeIn(delay: 380.ms),

            const SizedBox(height: FlickSpacing.md),

            _AiKeyCard().animate().fadeIn(delay: 400.ms),

            const SizedBox(height: FlickSpacing.lg),

            // Privacy Settings button
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
              ),
              icon: const Icon(Icons.shield_rounded, size: 18),
              label: const Text('Privacy & Data Settings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FlickColors.primary,
                side: const BorderSide(color: FlickColors.primary),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: FlickSpacing.md),

            // Database test button
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebugScreen()),
              ),
              icon: const Icon(Icons.biotech_rounded, size: 18),
              label: const Text('Test database connection'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FlickColors.textSecondary,
                side: const BorderSide(color: FlickColors.border),
              ),
            ).animate().fadeIn(delay: 420.ms),

            const SizedBox(height: FlickSpacing.lg),

            // Data pipeline note
            _SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.insights_rounded,
                      color: FlickColors.primary, size: 20),
                  const SizedBox(width: FlickSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detailed analytics coming',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Your learning data is being collected and will power '
                          'personalised insights — accuracy by skill, '
                          'time-per-question, and retention trends.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: FlickSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FlickSpacing.lg),
        decoration: BoxDecoration(
          color:        FlickColors.surface,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border:       Border.all(color: FlickColors.border),
        ),
        child: child,
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          vertical: FlickSpacing.md,
          horizontal: FlickSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:        FlickColors.surface,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border:       Border.all(color: FlickColors.border),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: FlickColors.primary,
                      fontWeight: FontWeight.w700,
                    )),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: FlickColors.textMuted)),
          ],
        ),
      );
}

class _LanguageProgressCard extends StatelessWidget {
  const _LanguageProgressCard({
    required this.language,
    required this.done,
    required this.total,
    required this.isActive,
  });

  final Language language;
  final int      done;
  final int      total;
  final bool     isActive;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(FlickSpacing.md),
      decoration: BoxDecoration(
        color:        FlickColors.surface,
        borderRadius: const BorderRadius.all(FlickRadius.lg),
        border: Border.all(
          color: isActive ? FlickColors.primary : FlickColors.border,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(language.flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: FlickSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(language.name,
                        style: Theme.of(context).textTheme.labelLarge),
                    if (isActive) ...[
                      const SizedBox(width: FlickSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: FlickColors.primaryDim,
                          borderRadius:
                              const BorderRadius.all(FlickRadius.full),
                        ),
                        child: Text('Active',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(color: FlickColors.primary)),
                      ),
                    ],
                    const Spacer(),
                    Text('$done / $total levels',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: FlickColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value:           progress,
                  backgroundColor: FlickColors.surfaceDim,
                  valueColor: AlwaysStoppedAnimation(
                      isActive ? FlickColors.primary : FlickColors.success),
                  borderRadius: const BorderRadius.all(FlickRadius.full),
                  minHeight: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiKeyCard extends StatefulWidget {
  const _AiKeyCard();
  @override
  State<_AiKeyCard> createState() => _AiKeyCardState();
}

class _AiKeyCardState extends State<_AiKeyCard> {
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    apiKeyService.loadKey().then((k) {
      if (mounted) setState(() => _hasKey = k != null && k.isNotEmpty);
    });
  }

  Future<void> _remove() async {
    await apiKeyService.clearKey();
    if (mounted) setState(() => _hasKey = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FlickSpacing.lg),
      decoration: BoxDecoration(
        color:        FlickColors.surface,
        borderRadius: const BorderRadius.all(FlickRadius.lg),
        border: Border.all(
          color: _hasKey ? FlickColors.success : FlickColors.border,
          width: _hasKey ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasKey ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
            color: _hasKey ? FlickColors.success : FlickColors.textMuted,
            size: 24,
          ),
          const SizedBox(width: FlickSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasKey ? 'AI lessons active' : 'AI lessons not set up',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: _hasKey
                            ? FlickColors.success
                            : FlickColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasKey
                      ? 'Lessons are generated by Gemini AI'
                      : 'Add your free Gemini key to unlock',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: FlickSpacing.sm),
          if (_hasKey)
            TextButton(
              onPressed: _remove,
              style: TextButton.styleFrom(
                  foregroundColor: FlickColors.error),
              child: const Text('Remove'),
            )
          else
            TextButton(
              onPressed: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ApiKeyScreen()),
                );
                if (saved == true && mounted) {
                  setState(() => _hasKey = true);
                }
              },
              child: const Text('Set up'),
            ),
        ],
      ),
    );
  }
}
