import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_theme.dart';
import '../main.dart' show authService;
import 'auth_screen.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlickColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: FlickSpacing.xl, vertical: FlickSpacing.xl),
          child: Column(
            children: [
              const Spacer(),

              // Logo icon med glöd-skugga
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:      FlickColors.primary.withValues(alpha: 0.22),
                      blurRadius: 40,
                      offset:     const Offset(0, 10),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/images/icon.svg',
                  width:  96,
                  height: 96,
                ),
              )
                  .animate()
                  .scale(
                    begin:    const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve:    Curves.elasticOut,
                  ),

              const SizedBox(height: FlickSpacing.xl),

              // Wordmark
              SvgPicture.asset(
                'assets/images/logo.svg',
                height: 56,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms),

              const SizedBox(height: FlickSpacing.sm),

              Text(
                'Language learning. Unlocked.',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: FlickColors.textSecondary),
              ).animate().fadeIn(delay: 320.ms, duration: 400.ms),

              const SizedBox(height: FlickSpacing.xl * 2),

              // Feature pills
              Wrap(
                spacing:    FlickSpacing.sm,
                runSpacing: FlickSpacing.sm,
                alignment:  WrapAlignment.center,
                children: const [
                  _FeaturePill('✨ AI-powered lessons'),
                  _FeaturePill('🧩 Puzzle games'),
                  _FeaturePill('🌍 20 languages'),
                  _FeaturePill('❤️ Lives system'),
                ],
              ).animate().fadeIn(delay: 440.ms, duration: 400.ms),

              const Spacer(flex: 2),

              // CTAs
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthScreen(
                            authService: authService,
                            isLogin: false,
                          ),
                        ),
                      );
                      // After signup, always navigate to onboarding regardless of currentUser state
                      // because new users must see GDPR consent screen before using the app
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnboardingScreen(),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Create free account'),
                ),
              ).animate().fadeIn(delay: 560.ms),

              const SizedBox(height: FlickSpacing.md),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthScreen(
                            authService: authService,
                            isLogin: true,
                          ),
                        ),
                      );
                      if (context.mounted && authService.currentUser != null) {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => const MainScreen()));
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FlickColors.primary,
                    side: const BorderSide(color: FlickColors.primary),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(FlickRadius.full)),
                    padding: const EdgeInsets.symmetric(
                        vertical: FlickSpacing.md + 2),
                  ),
                  child: const Text('I already have an account'),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: FlickSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: FlickSpacing.md, vertical: FlickSpacing.xs + 2),
        decoration: BoxDecoration(
          color:        FlickColors.surfaceDim,
          borderRadius: const BorderRadius.all(FlickRadius.full),
          border:       Border.all(color: FlickColors.border),
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600)),
      );
}
