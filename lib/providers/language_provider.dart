import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../models/language.dart';

class LanguageNotifier extends Notifier<Language> {
  @override
  Language build() => kLanguages.first;

  void selectLanguage(Language language) {
    final previous = state.code;
    state = language;
    EventSensor.instance.emit('language_selected', {
      'language_code':  language.code,
      'previous_code':  previous,
    });
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, Language>(LanguageNotifier.new);
