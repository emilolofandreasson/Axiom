import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../core/theme/app_theme.dart';
import '../models/language.dart';
import '../providers/language_provider.dart';
import 'main_screen.dart';

// Current privacy policy version — bump when policy changes.
const _kPolicyVersion = '1.0';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int  _currentPage = 0;

  // Consent state — both off by default (GDPR requires active opt-in).
  bool _consentAnonymous = false;
  bool _consentPartner   = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 3) {
      _pageController.nextPage(duration: 350.ms, curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setBool('consent_anonymous_stats', _consentAnonymous);
    await prefs.setBool('consent_partner_profile',  _consentPartner);
    await prefs.setString('consent_policy_version', _kPolicyVersion);
    await prefs.setString('consent_shown_at', DateTime.now().toIso8601String());

    // Analytics + consent log (non-blocking).
    _logConsentToSupabase();
    EventSensor.instance.emit('onboarding_completed', {
      'consent_anonymous_stats': _consentAnonymous,
      'consent_partner_profile': _consentPartner,
      'policy_version':          _kPolicyVersion,
    });

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  Future<void> _logConsentToSupabase() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      final rows = [
        {
          'user_id': uid,
          'purpose': 'anonymous_stats',
          'granted': _consentAnonymous,
          'version': _kPolicyVersion,
        },
        {
          'user_id': uid,
          'purpose': 'partner_profile',
          'granted': _consentPartner,
          'version': _kPolicyVersion,
        },
      ];

      await Supabase.instance.client.from('consent_log').insert(rows);
    } catch (e) {
      debugPrint('[Consent] Supabase log failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlickColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  const _WelcomePage(),
                  const _HowItWorksPage(),
                  const _ChooseLanguagePage(),
                  _ConsentPage(
                    consentAnonymous: _consentAnonymous,
                    consentPartner:   _consentPartner,
                    onAnonymousChanged: (v) => setState(() => _consentAnonymous = v),
                    onPartnerChanged:   (v) => setState(() => _consentPartner   = v),
                  ),
                ],
              ),
            ),
            _BottomBar(
              currentPage: _currentPage,
              totalPages:  4,
              onContinue:  _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FlickSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌍', style: TextStyle(fontSize: 64)),
          const SizedBox(height: FlickSpacing.lg),
          Text(
            'Learn any language.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: FlickSpacing.md),
          Text(
            'Daily lessons. Puzzle games. Real conversations.',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: FlickColors.textSecondary,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FlickSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: FlickSpacing.xl),
          const _FeatureRow(
            icon: Icons.quiz_outlined,
            label: 'Answer questions to earn XP',
          ),
          const SizedBox(height: FlickSpacing.lg),
          const _FeatureRow(
            icon: Icons.grid_view_rounded,
            label: 'Match word pairs in puzzles',
          ),
          const SizedBox(height: FlickSpacing.lg),
          const _FeatureRow(
            icon: Icons.auto_awesome_rounded,
            label: 'Chat with an AI tutor',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: FlickColors.primary, size: 26),
        const SizedBox(width: FlickSpacing.md),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _ChooseLanguagePage extends ConsumerWidget {
  const _ChooseLanguagePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageProvider);

    return Padding(
      padding: const EdgeInsets.only(
        left: FlickSpacing.lg,
        right: FlickSpacing.lg,
        top: FlickSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you want to learn?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: FlickSpacing.lg),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: FlickSpacing.md,
                crossAxisSpacing: FlickSpacing.md,
                childAspectRatio: 1.1,
              ),
              itemCount: kLanguages.length,
              itemBuilder: (context, i) {
                final lang = kLanguages[i];
                final isSelected = lang.code == selected.code;

                return _OnboardingLanguageCard(
                  language: lang,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(languageProvider.notifier).selectLanguage(lang);
                  },
                )
                    .animate(delay: (i * 40).ms)
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.08, end: 0, duration: 250.ms);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _OnboardingLanguageCard extends StatelessWidget {
  const _OnboardingLanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final Language language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(FlickSpacing.md),
        decoration: BoxDecoration(
          color: FlickColors.surface,
          borderRadius: const BorderRadius.all(FlickRadius.lg),
          border: Border.all(
            color: isSelected ? FlickColors.primary : FlickColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.flag, style: const TextStyle(fontSize: 36)),
                const Spacer(),
                Text(
                  language.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: FlickColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  language.nativeName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FlickColors.textMuted,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: FlickColors.primary,
                    borderRadius: BorderRadius.all(FlickRadius.full),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            if (!language.hasContent)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: FlickColors.textMuted.withOpacity(0.15),
                    borderRadius: const BorderRadius.all(FlickRadius.full),
                  ),
                  child: const Text(
                    'Coming soon',
                    style: TextStyle(
                      fontSize: 9,
                      color: FlickColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Consent page
// ---------------------------------------------------------------------------

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({
    required this.consentAnonymous,
    required this.consentPartner,
    required this.onAnonymousChanged,
    required this.onPartnerChanged,
  });

  final bool consentAnonymous;
  final bool consentPartner;
  final ValueChanged<bool> onAnonymousChanged;
  final ValueChanged<bool> onPartnerChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        FlickSpacing.xl, FlickSpacing.xl, FlickSpacing.xl, FlickSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤝', style: TextStyle(fontSize: 52))
              .animate().fadeIn(duration: 300.ms),

          const SizedBox(height: FlickSpacing.lg),

          Text(
            'How we keep Axiom free',
            style: Theme.of(context).textTheme.displaySmall,
          ).animate().fadeIn(delay: 80.ms, duration: 350.ms),

          const SizedBox(height: FlickSpacing.md),

          Text(
            'No subscription. No ads.\n\n'
            'Instead, we share anonymous learning profiles with trusted '
            'partners — travel companies, language schools and cultural '
            'organisations — who want to reach people like you.\n\n'
            'We never sell your name, e-mail, exact location or any '
            'directly identifying information.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: FlickColors.textSecondary, height: 1.6),
          ).animate().fadeIn(delay: 160.ms, duration: 350.ms),

          const SizedBox(height: FlickSpacing.xl),

          _ConsentToggle(
            title:       'Anonymous usage statistics',
            description: 'Helps us improve Axiom and shows aggregated '
                'trends to partners (e.g. "Spanish is popular in Sweden"). '
                'No individual is identifiable.',
            value:    consentAnonymous,
            onChange: onAnonymousChanged,
            delay:    240,
          ),

          const SizedBox(height: FlickSpacing.md),

          _ConsentToggle(
            title:       'Personalised learning profile',
            description: 'Shares your language goals, lesson topics and '
                'engagement level with selected partners. You may receive '
                'relevant offers (e.g. travel deals for Spanish-speaking '
                'destinations). This is how we earn revenue.',
            value:    consentPartner,
            onChange: onPartnerChanged,
            delay:    320,
            highlighted: true,
          ),

          const SizedBox(height: FlickSpacing.xl),

          Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: FlickColors.textMuted),
              children: [
                const TextSpan(text: 'You can change these choices at any '
                    'time in Settings → Privacy. By tapping "Get started" '
                    'you accept our '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: FlickColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: open privacy policy URL
                    },
                ),
                const TextSpan(text: ' (v$_kPolicyVersion).'),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 350.ms),

          const SizedBox(height: FlickSpacing.md),
        ],
      ),
    );
  }
}

class _ConsentToggle extends StatelessWidget {
  const _ConsentToggle({
    required this.title,
    required this.description,
    required this.value,
    required this.onChange,
    required this.delay,
    this.highlighted = false,
  });

  final String title;
  final String description;
  final bool   value;
  final ValueChanged<bool> onChange;
  final int    delay;
  final bool   highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 200.ms,
      padding: const EdgeInsets.all(FlickSpacing.md),
      decoration: BoxDecoration(
        color: value
            ? (highlighted ? FlickColors.primaryDim : FlickColors.surfaceDim)
            : FlickColors.surface,
        borderRadius: const BorderRadius.all(FlickRadius.lg),
        border: Border.all(
          color: value ? FlickColors.primary : FlickColors.border,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: FlickColors.textSecondary,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FlickSpacing.sm),
          Switch(
            value:          value,
            onChanged:      onChange,
            activeColor:    FlickColors.primary,
            inactiveThumbColor: FlickColors.textMuted,
            inactiveTrackColor: FlickColors.surfaceDim,
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.06, end: 0);
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentPage,
    required this.totalPages,
    required this.onContinue,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FlickSpacing.xl,
        FlickSpacing.md,
        FlickSpacing.xl,
        FlickSpacing.xl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(totalPages, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(right: FlickSpacing.xs),
                width:  active ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? FlickColors.primary : FlickColors.border,
                  borderRadius: const BorderRadius.all(FlickRadius.full),
                ),
              );
            }),
          ),
          ElevatedButton(
            onPressed: onContinue,
            child: Text(currentPage == totalPages - 1 ? 'Get started' : 'Continue'),
          ),
        ],
      ),
    );
  }
}
