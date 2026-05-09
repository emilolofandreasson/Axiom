import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../models/language.dart';
import '../providers/language_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: 350.ms,
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
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
                children: const [
                  _WelcomePage(),
                  _HowItWorksPage(),
                  _ChooseLanguagePage(),
                ],
              ),
            ),
            _BottomBar(
              currentPage: _currentPage,
              onContinue: _next,
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentPage,
    required this.onContinue,
  });

  final int currentPage;
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
            children: List.generate(3, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(right: FlickSpacing.xs),
                width: active ? 20 : 8,
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
            child: Text(currentPage == 2 ? 'Get started' : 'Continue'),
          ),
        ],
      ),
    );
  }
}
