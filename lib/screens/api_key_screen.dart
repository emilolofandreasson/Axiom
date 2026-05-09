import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../main.dart' show apiKeyService;

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key, this.isOnboarding = false});
  final bool isOnboarding;

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _ctrl     = TextEditingController();
  bool  _loading  = false;
  bool  _success  = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Paste your API key first.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final ok = await apiKeyService.saveKey(key);

    if (!mounted) return;
    if (ok) {
      setState(() { _loading = false; _success = true; });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _error   = 'Key verification failed. Make sure you copied the full key.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: widget.isOnboarding
          ? null
          : AppBar(title: const Text('AI Tutor key')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FlickSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isOnboarding) const SizedBox(height: FlickSpacing.xl),

              // Icon
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color:  FlickColors.primaryDim,
                  shape:  BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: FlickColors.primary, size: 32),
              ).animate().scale(
                    begin: const Offset(0.7, 0.7),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: FlickSpacing.xl),

              Text(
                'Activate AI lessons',
                style: Theme.of(context).textTheme.displaySmall,
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: FlickSpacing.sm),

              Text(
                'Axiom uses Google Gemini to generate unlimited lessons '
                'tailored to your level — for free. Each user brings their '
                'own key so your learning is always private.',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: FlickColors.textSecondary),
              ).animate().fadeIn(delay: 160.ms),

              const SizedBox(height: FlickSpacing.xl),

              // Steps
              _Step(
                number: '1',
                text: 'Open Google AI Studio — search "Google AI Studio" '
                    'or go to aistudio.google.com',
                delay: 220.ms,
              ),
              _Step(
                number: '2',
                text: 'Click "Get API key" → "Create API key" → copy it',
                delay: 280.ms,
              ),
              _Step(
                number: '3',
                text: 'Paste it below — we verify and store it securely on your device.',
                delay: 340.ms,
              ),

              const SizedBox(height: FlickSpacing.xl),

              TextField(
                controller:   _ctrl,
                obscureText:  true,
                decoration: const InputDecoration(
                  hintText: 'AIzaSy...',
                  prefixIcon: Icon(Icons.key_rounded,
                      color: FlickColors.textMuted, size: 20),
                ),
                onSubmitted: (_) => _save(),
              ).animate().fadeIn(delay: 400.ms),

              if (_error != null) ...[
                const SizedBox(height: FlickSpacing.md),
                Container(
                  padding: const EdgeInsets.all(FlickSpacing.md),
                  decoration: BoxDecoration(
                    color:        FlickColors.errorDim,
                    borderRadius: const BorderRadius.all(FlickRadius.md),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: FlickColors.error, fontSize: 14)),
                ),
              ],

              const SizedBox(height: FlickSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading || _success ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : _success
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('All set!'),
                              ],
                            )
                          : const Text('Verify & save key'),
                ),
              ).animate().fadeIn(delay: 460.ms),

              const SizedBox(height: FlickSpacing.md),

              if (widget.isOnboarding)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Skip for now — use basic lessons',
                      style: TextStyle(color: FlickColors.textMuted),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: FlickSpacing.lg),

              // Security note
              Container(
                padding: const EdgeInsets.all(FlickSpacing.md),
                decoration: BoxDecoration(
                  color:        FlickColors.surfaceDim,
                  borderRadius: const BorderRadius.all(FlickRadius.md),
                  border:       Border.all(color: FlickColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 16, color: FlickColors.textMuted),
                    const SizedBox(width: FlickSpacing.sm),
                    Expanded(
                      child: Text(
                        'Your key is encrypted on your device and never shared '
                        'with Axiom servers. It is only sent directly to Google.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: FlickColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 540.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, required this.delay});
  final String   number;
  final String   text;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FlickSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              color:  FlickColors.primaryDim,
              shape:  BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(number,
                style: const TextStyle(
                    color: FlickColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: FlickSpacing.md),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ).animate().fadeIn(duration: 250.ms, delay: delay),
    );
  }
}
