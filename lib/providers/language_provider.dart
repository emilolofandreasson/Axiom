import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/language.dart';

class LanguageNotifier extends Notifier<Language> {
  @override
  Language build() => kLanguages.first;

  void selectLanguage(Language language) {
    state = language;
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, Language>(LanguageNotifier.new);
