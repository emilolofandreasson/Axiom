import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/language.dart';
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
  bool _saving  = false;
  bool _uploading = false;
  String? _photoUrl;

  final _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.profile.name);
    _bioCtrl    = TextEditingController(text: widget.profile.bio);
    _nativeLang = widget.profile.nativeLanguage;
    _photoUrl   = widget.profile.photoUrl;
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
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _picking ? null : _pickAvatar,
                child: Stack(
                  children: [
                    _Avatar(photoUrl: _photoUrl, size: 90),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(
                          color: FlickColors.primary, shape: BoxShape.circle),
                        child: _uploading
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt_rounded,
                                size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: FlickSpacing.xl),

            _label(context, 'Display name'),
            const SizedBox(height: FlickSpacing.sm),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Your name'),
            ),

            const SizedBox(height: FlickSpacing.lg),

            _label(context, 'Bio'),
            const SizedBox(height: FlickSpacing.sm),
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'A short intro about yourself…'),
            ),

            const SizedBox(height: FlickSpacing.lg),

            _label(context, 'Native language'),
            const SizedBox(height: FlickSpacing.sm),
            _NativeLanguagePicker(
              selected: _nativeLang,
              onChanged: (code) => setState(() => _nativeLang = code),
            ),

            const SizedBox(height: FlickSpacing.xl),
          ],
        ),
      ),
    );
  }

  bool get _picking => _uploading;

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: FlickColors.textSecondary),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.size});
  final String? photoUrl;
  final double  size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: size / 2,
        backgroundColor: FlickColors.primaryDim,
        backgroundImage:
            photoUrl != null ? NetworkImage(photoUrl!) : null,
        child: photoUrl == null
            ? Icon(Icons.person_rounded,
                size: size * 0.5, color: FlickColors.primary)
            : null,
      );
}

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
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: const InputDecoration(),
      items: _langs.map((l) => DropdownMenuItem(
            value: l.$1,
            child: Text('${l.$2}  ${l.$3}'),
          )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
