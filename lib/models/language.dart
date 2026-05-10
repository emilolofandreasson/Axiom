import 'package:flutter/foundation.dart';

@immutable
class Language {
  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.rtl = false,
    this.hasContent = false,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool rtl;
  final bool hasContent;
}

const kLanguages = <Language>[
  Language(code: 'es', name: 'Spanish',          nativeName: 'Español',    flag: '🇪🇸', hasContent: true),
  Language(code: 'fr', name: 'French',           nativeName: 'Français',   flag: '🇫🇷', hasContent: true),
  Language(code: 'de', name: 'German',           nativeName: 'Deutsch',    flag: '🇩🇪', hasContent: true),
  Language(code: 'it', name: 'Italian',          nativeName: 'Italiano',   flag: '🇮🇹', hasContent: true),
  Language(code: 'pt', name: 'Portuguese',       nativeName: 'Português',  flag: '🇧🇷', hasContent: true),
  Language(code: 'ja', name: 'Japanese',         nativeName: '日本語',      flag: '🇯🇵', hasContent: true),
  Language(code: 'ko', name: 'Korean',           nativeName: '한국어',      flag: '🇰🇷', hasContent: true),
  Language(code: 'zh', name: 'Mandarin Chinese', nativeName: '普通话',      flag: '🇨🇳', hasContent: true),
  Language(code: 'ar', name: 'Arabic',           nativeName: 'العربية',    flag: '🇸🇦', rtl: true,  hasContent: true),
  Language(code: 'ru', name: 'Russian',          nativeName: 'Русский',    flag: '🇷🇺', hasContent: true),
  Language(code: 'nl', name: 'Dutch',            nativeName: 'Nederlands', flag: '🇳🇱', hasContent: true),
  Language(code: 'sv', name: 'Swedish',          nativeName: 'Svenska',    flag: '🇸🇪', hasContent: true),
  Language(code: 'no', name: 'Norwegian',        nativeName: 'Norsk',      flag: '🇳🇴', hasContent: true),
  Language(code: 'da', name: 'Danish',           nativeName: 'Dansk',      flag: '🇩🇰', hasContent: true),
  Language(code: 'pl', name: 'Polish',           nativeName: 'Polski',     flag: '🇵🇱', hasContent: true),
  Language(code: 'tr', name: 'Turkish',          nativeName: 'Türkçe',     flag: '🇹🇷', hasContent: true),
  Language(code: 'hi', name: 'Hindi',            nativeName: 'हिन्दी',     flag: '🇮🇳', hasContent: true),
  Language(code: 'el', name: 'Greek',            nativeName: 'Ελληνικά',   flag: '🇬🇷', hasContent: true),
  Language(code: 'he', name: 'Hebrew',           nativeName: 'עברית',      flag: '🇮🇱', rtl: true,  hasContent: true),
  Language(code: 'vi', name: 'Vietnamese',       nativeName: 'Tiếng Việt', flag: '🇻🇳', hasContent: true),
];
