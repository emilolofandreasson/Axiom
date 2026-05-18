import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/language.dart';
import '../providers/language_provider.dart';

class LanguagePickerScreen extends ConsumerWidget {
  const LanguagePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: const Text('Choose a language'),
        leading: const BackButton(),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(FlickSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          mainAxisSpacing:  FlickSpacing.md,
          crossAxisSpacing: FlickSpacing.md,
          childAspectRatio: 1.1,
        ),
        itemCount: kLanguages.length,
        itemBuilder: (context, i) {
          final lang = kLanguages[i];
          final isSelected = lang.code == selected.code;

          return _LanguageCard(
            language:   lang,
            isSelected: isSelected,
            onTap: lang.hasContent
                ? () async {
                    await ref.read(languageProvider.notifier).selectLanguage(lang);
                    if (context.mounted) Navigator.pop(context);
                  }
                : null,
          )
              .animate(delay: (i * 40).ms)
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.08, end: 0, duration: 250.ms);
        },
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final Language language;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(FlickSpacing.md),
        decoration: BoxDecoration(
          color: language.hasContent ? FlickColors.surface : FlickColors.surfaceDim,
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

            // Selected checkmark
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color:        FlickColors.primary,
                    borderRadius: BorderRadius.all(FlickRadius.full),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                ),
              ),

            // Coming soon chip
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
                    color: FlickColors.textMuted.withValues(alpha: 0.15),
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
