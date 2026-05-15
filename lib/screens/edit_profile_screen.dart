import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});
  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late String  _nativeLang;
  late String? _motivation;
  late String? _learningGoal;
  late Set<String> _interests;
  late String? _country;
  late String? _availability;
  late int?    _birthYear;

  bool _saving    = false;
  bool _uploading = false;
  String? _photoUrl;

  final _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.profile.name);
    _bioCtrl      = TextEditingController(text: widget.profile.bio);
    _nativeLang   = widget.profile.nativeLanguage;
    _photoUrl     = widget.profile.photoUrl;
    _motivation   = widget.profile.motivation;
    _learningGoal = widget.profile.learningGoal;
    _interests    = Set.from(widget.profile.interests);
    _country      = widget.profile.country;
    _availability = widget.profile.availability;
    _birthYear    = widget.profile.birthYear;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    setState(() => _uploading = true);
    final url = await _profileService.pickAndUploadAvatar();
    if (mounted) setState(() { _photoUrl = url ?? _photoUrl; _uploading = false; });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.profile.copyWith(
      name:           _nameCtrl.text.trim(),
      bio:            _bioCtrl.text.trim(),
      nativeLanguage: _nativeLang,
      photoUrl:       _photoUrl,
      motivation:     _motivation,
      learningGoal:   _learningGoal,
      interests:      _interests.toList(),
      country:        _country,
      availability:   _availability,
      birthYear:      _birthYear,
    );
    await _profileService.saveProfile(updated);
    if (mounted) Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FlickSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Avatar ────────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _uploading ? null : _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: FlickColors.primaryDim,
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(_photoUrl!)
                          : null,
                      child: _photoUrl == null
                          ? const Icon(Icons.person_rounded,
                              size: 44, color: FlickColors.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(
                            color: FlickColors.primary,
                            shape: BoxShape.circle),
                        child: _uploading
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt_rounded,
                                size: 17, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: FlickSpacing.xl),

            // ── Identity ──────────────────────────────────────────────────
            _SectionHeader('Identity'),
            const SizedBox(height: FlickSpacing.sm),

            _label(context, 'Display name'),
            const SizedBox(height: FlickSpacing.xs),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Your name'),
            ),

            const SizedBox(height: FlickSpacing.md),

            _label(context, 'Bio'),
            const SizedBox(height: FlickSpacing.xs),
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'A short intro about yourself…'),
            ),

            const SizedBox(height: FlickSpacing.md),

            _label(context, 'Country'),
            const SizedBox(height: FlickSpacing.xs),
            _CountryPicker(
              selected: _country,
              onChanged: (v) => setState(() => _country = v),
            ),

            const SizedBox(height: FlickSpacing.md),

            _label(context, 'Birth year'),
            const SizedBox(height: FlickSpacing.xs),
            _BirthYearPicker(
              selected: _birthYear,
              onChanged: (v) => setState(() => _birthYear = v),
            ),

            const SizedBox(height: FlickSpacing.md),

            _label(context, 'Native language'),
            const SizedBox(height: FlickSpacing.xs),
            _NativeLanguagePicker(
              selected: _nativeLang,
              onChanged: (v) => setState(() => _nativeLang = v),
            ),

            const SizedBox(height: FlickSpacing.xl),

            // ── Learning persona ──────────────────────────────────────────
            _SectionHeader('Why are you learning?'),
            const SizedBox(height: FlickSpacing.sm),
            _label(context, 'Motivation'),
            const SizedBox(height: FlickSpacing.xs),
            _ChipSelector<String>(
              options: const {
                'travel':  ('✈️', 'Travel'),
                'work':    ('💼', 'Work'),
                'family':  ('👨‍👩‍👧', 'Family'),
                'culture': ('🎭', 'Culture'),
                'fun':     ('🎉', 'Just for fun'),
              },
              selected: _motivation,
              onSelected: (v) => setState(() => _motivation = v),
            ),

            const SizedBox(height: FlickSpacing.md),

            _label(context, 'Learning goal'),
            const SizedBox(height: FlickSpacing.xs),
            _ChipSelector<String>(
              options: const {
                'conversational': ('💬', 'Conversational'),
                'business':       ('📊', 'Business'),
                'travel':         ('🗺️', 'Travel phrases'),
                'academic':       ('📚', 'Academic'),
              },
              selected: _learningGoal,
              onSelected: (v) => setState(() => _learningGoal = v),
            ),

            const SizedBox(height: FlickSpacing.md),

            _label(context, 'Study time'),
            const SizedBox(height: FlickSpacing.xs),
            _ChipSelector<String>(
              options: const {
                'morning':   ('🌅', 'Morning'),
                'afternoon': ('☀️', 'Afternoon'),
                'evening':   ('🌙', 'Evening'),
                'flexible':  ('🔄', 'Flexible'),
              },
              selected: _availability,
              onSelected: (v) => setState(() => _availability = v),
            ),

            const SizedBox(height: FlickSpacing.xl),

            // ── Interests ─────────────────────────────────────────────────
            _SectionHeader('Interests'),
            const SizedBox(height: FlickSpacing.xs),
            Text(
              'Select all that apply — used to personalise your content.',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: FlickColors.textSecondary),
            ),
            const SizedBox(height: FlickSpacing.sm),
            _MultiChipSelector(
              options: const {
                'food':     ('🍜', 'Food & drink'),
                'travel':   ('🌍', 'Travel'),
                'music':    ('🎵', 'Music'),
                'sport':    ('⚽', 'Sport'),
                'film':     ('🎬', 'Film & TV'),
                'tech':     ('💻', 'Technology'),
                'books':    ('📖', 'Books'),
                'nature':   ('🌿', 'Nature'),
                'fashion':  ('👗', 'Fashion'),
                'business': ('💼', 'Business'),
              },
              selected: _interests,
              onToggled: (tag, selected) {
                setState(() {
                  if (selected) _interests.add(tag);
                  else          _interests.remove(tag);
                });
              },
            ),

            const SizedBox(height: FlickSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(color: FlickColors.textSecondary),
      );
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: FlickSpacing.sm),
          const Divider(),
          const SizedBox(height: FlickSpacing.sm),
        ],
      );
}

// ── Single-select chip row ────────────────────────────────────────────────────

class _ChipSelector<T> extends StatelessWidget {
  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final Map<T, (String, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: FlickSpacing.sm,
      runSpacing: FlickSpacing.sm,
      children: options.entries.map((e) {
        final isSelected = e.key == selected;
        return GestureDetector(
          onTap: () => onSelected(e.key),
          child: AnimatedContainer(
            duration: 150.ms,
            padding: const EdgeInsets.symmetric(
                horizontal: FlickSpacing.md, vertical: FlickSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? FlickColors.primaryDim : FlickColors.surface,
              borderRadius: const BorderRadius.all(FlickRadius.full),
              border: Border.all(
                color: isSelected ? FlickColors.primary : FlickColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.value.$1, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  e.value.$2,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: isSelected
                            ? FlickColors.primary
                            : FlickColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Multi-select chip grid ────────────────────────────────────────────────────

class _MultiChipSelector extends StatelessWidget {
  const _MultiChipSelector({
    required this.options,
    required this.selected,
    required this.onToggled,
  });

  final Map<String, (String, String)> options;
  final Set<String> selected;
  final void Function(String tag, bool isSelected) onToggled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: FlickSpacing.sm,
      runSpacing: FlickSpacing.sm,
      children: options.entries.map((e) {
        final isSelected = selected.contains(e.key);
        return GestureDetector(
          onTap: () => onToggled(e.key, !isSelected),
          child: AnimatedContainer(
            duration: 150.ms,
            padding: const EdgeInsets.symmetric(
                horizontal: FlickSpacing.md, vertical: FlickSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? FlickColors.primaryDim : FlickColors.surface,
              borderRadius: const BorderRadius.all(FlickRadius.full),
              border: Border.all(
                color: isSelected ? FlickColors.primary : FlickColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.value.$1, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  e.value.$2,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: isSelected
                            ? FlickColors.primary
                            : FlickColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_rounded,
                      size: 14, color: FlickColors.primary),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Birth year picker ─────────────────────────────────────────────────────────

class _BirthYearPicker extends StatelessWidget {
  const _BirthYearPicker({required this.selected, required this.onChanged});
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(80, (i) => currentYear - 13 - i); // 13–92 years old

    return DropdownButtonFormField<int>(
      value: selected,
      decoration: const InputDecoration(hintText: 'Select birth year'),
      items: [
        const DropdownMenuItem(value: null, child: Text('— Not specified —')),
        ...years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))),
      ],
      onChanged: onChanged,
    );
  }
}

// ── Country picker ────────────────────────────────────────────────────────────

class _CountryPicker extends StatelessWidget {
  const _CountryPicker({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _countries = [
    ('SE', '🇸🇪', 'Sweden'),
    ('US', '🇺🇸', 'United States'),
    ('GB', '🇬🇧', 'United Kingdom'),
    ('DE', '🇩🇪', 'Germany'),
    ('FR', '🇫🇷', 'France'),
    ('ES', '🇪🇸', 'Spain'),
    ('NO', '🇳🇴', 'Norway'),
    ('DK', '🇩🇰', 'Denmark'),
    ('FI', '🇫🇮', 'Finland'),
    ('NL', '🇳🇱', 'Netherlands'),
    ('IT', '🇮🇹', 'Italy'),
    ('PL', '🇵🇱', 'Poland'),
    ('AU', '🇦🇺', 'Australia'),
    ('CA', '🇨🇦', 'Canada'),
    ('JP', '🇯🇵', 'Japan'),
    ('BR', '🇧🇷', 'Brazil'),
    ('IN', '🇮🇳', 'India'),
    ('CN', '🇨🇳', 'China'),
    ('MX', '🇲🇽', 'Mexico'),
    ('ZA', '🇿🇦', 'South Africa'),
  ];

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: selected,
        decoration: const InputDecoration(hintText: 'Select country'),
        items: [
          const DropdownMenuItem(value: null, child: Text('— Not specified —')),
          ..._countries.map((c) => DropdownMenuItem(
                value: c.$1,
                child: Text('${c.$2}  ${c.$3}'),
              )),
        ],
        onChanged: onChanged,
      );
}

// ── Native language picker ────────────────────────────────────────────────────

class _NativeLanguagePicker extends StatelessWidget {
  const _NativeLanguagePicker({
    required this.selected,
    required this.onChanged,
  });
  final String selected;
  final ValueChanged<String> onChanged;

  static const _langs = [
    ('en', '🇬🇧', 'English'),
    ('sv', '🇸🇪', 'Swedish'),
    ('de', '🇩🇪', 'German'),
    ('fr', '🇫🇷', 'French'),
    ('es', '🇪🇸', 'Spanish'),
    ('ar', '🇸🇦', 'Arabic'),
    ('zh', '🇨🇳', 'Chinese'),
    ('ja', '🇯🇵', 'Japanese'),
    ('ko', '🇰🇷', 'Korean'),
    ('pt', '🇧🇷', 'Portuguese'),
    ('no', '🇳🇴', 'Norwegian'),
    ('da', '🇩🇰', 'Danish'),
    ('fi', '🇫🇮', 'Finnish'),
    ('nl', '🇳🇱', 'Dutch'),
    ('pl', '🇵🇱', 'Polish'),
    ('it', '🇮🇹', 'Italian'),
    ('hi', '🇮🇳', 'Hindi'),
  ];

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: selected,
        decoration: const InputDecoration(),
        items: _langs
            .map((l) => DropdownMenuItem(
                  value: l.$1,
                  child: Text('${l.$2}  ${l.$3}'),
                ))
            .toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      );
}
