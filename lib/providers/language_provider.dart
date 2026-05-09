import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

class LanguageNotifier extends Notifier<Language> {
  @override
  Language build() {
    _loadFromPrefs();
    return kLanguages.first;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('selected_language_code');
    if (code != null) {
      state = kLanguages.firstWhere(
        (l) => l.code == code,
        orElse: () => kLanguages.first,
      );
    }
  }

  void selectLanguage(Language language) {
    final previous = state.code;
    state = language;
    EventSensor.instance.emit('language_selected', {
      'language_code':  language.code,
      'previous_code':  previous,
    });
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language_code', state.code);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, Language>(LanguageNotifier.new);
