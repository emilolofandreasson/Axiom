import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';

const String _kPolicyVersion = '1.0';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _loading = true;
  String? _error;
  bool _consentAnonymous = false;
  bool _consentPartner = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    try {
      setState(() { _loading = true; _error = null; });

      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        setState(() => _error = 'Not authenticated');
        return;
      }

      final rows = await Supabase.instance.client
          .from('consent_log')
          .select()
          .eq('user_id', uid)
          .order('granted_at', ascending: false);

      // Find latest consent for each purpose
      bool? anonConsent;
      bool? partnerConsent;

      for (final row in rows as List) {
        final purpose = row['purpose'] as String?;
        final granted = row['granted'] as bool?;

        if (purpose == 'anonymous_stats' && anonConsent == null) {
          anonConsent = granted ?? false;
        } else if (purpose == 'partner_profile' && partnerConsent == null) {
          partnerConsent = granted ?? false;
        }
      }

      setState(() {
        _consentAnonymous = anonConsent ?? false;
        _consentPartner = partnerConsent ?? false;
        _loading = false;
        _hasChanged = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load consent: $e';
        _loading = false;
      });
    }
  }

  Future<void> _saveConsent() async {
    try {
      setState(() => _loading = true);

      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      // Insert new consent records (immutable log)
      final newRecords = [
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

      await Supabase.instance.client.from('consent_log').insert(newRecords);

      setState(() {
        _loading = false;
        _hasChanged = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings saved ✓')),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to save: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Error banner
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(FlickSpacing.lg),
                      padding: const EdgeInsets.all(FlickSpacing.md),
                      decoration: BoxDecoration(
                        color: FlickColors.errorDim,
                        borderRadius: const BorderRadius.all(FlickRadius.lg),
                      ),
                      child: Text(
                        _error!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: FlickColors.error),
                      ),
                    ),
                  ),

                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(FlickSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How we use your data',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: FlickSpacing.sm),
                        Text(
                          'You can change these settings at any time. We never share your name, '
                          'email, or exact location.',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: FlickColors.textSecondary,
                                height: 1.6,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Consent toggles
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: FlickSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ConsentToggle(
                        title: 'Anonymous usage statistics',
                        description:
                            'Helps us improve Axiom and shows aggregated trends to partners '
                            '(e.g. "Spanish is popular in Sweden"). No individual is identifiable.',
                        value: _consentAnonymous,
                        onChange: (v) {
                          setState(() {
                            _consentAnonymous = v;
                            _hasChanged = true;
                          });
                        },
                      ),
                      const SizedBox(height: FlickSpacing.md),
                      _ConsentToggle(
                        title: 'Personalised learning profile',
                        description:
                            'Shares your language goals, lesson topics and engagement level with '
                            'selected partners. You may receive relevant offers (e.g. travel deals for '
                            'Spanish-speaking destinations). This is how we earn revenue.',
                        value: _consentPartner,
                        onChange: (v) {
                          setState(() {
                            _consentPartner = v;
                            _hasChanged = true;
                          });
                        },
                        highlighted: true,
                      ),
                      const SizedBox(height: FlickSpacing.xl),
                      if (_hasChanged)
                        ElevatedButton(
                          onPressed: _saveConsent,
                          child: const Text('Save changes'),
                        ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: FlickSpacing.lg),
                      Text(
                        'Policy version: v$_kPolicyVersion',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: FlickColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: FlickSpacing.xl),
                    ]),
                  ),
                ),
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
    this.highlighted = false,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChange;
  final bool highlighted;

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
                Text(title, style: Theme.of(context).textTheme.labelLarge),
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
            value: value,
            onChanged: onChange,
            activeColor: FlickColors.primary,
            inactiveThumbColor: FlickColors.textMuted,
            inactiveTrackColor: FlickColors.surfaceDim,
          ),
        ],
      ),
    );
  }
}
