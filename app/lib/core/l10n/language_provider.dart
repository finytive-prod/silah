import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageNotifier extends StateNotifier<bool> {
  // true = English by default, false = Tamil
  LanguageNotifier() : super(true);

  void toggleLanguage() {
    state = !state;
  }

  void setEnglish(bool isEnglish) {
    state = isEnglish;
  }

  String tr({required String en, required String ta}) {
    return state ? en : ta;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, bool>((ref) {
  return LanguageNotifier();
});
