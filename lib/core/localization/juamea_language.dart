/// Supported application and AI response languages for Juamea across East Africa.
enum JuameaLanguage {
  fr,
  en,
  sw,
}

extension JuameaLanguageX on JuameaLanguage {
  String get code {
    switch (this) {
      case JuameaLanguage.fr:
        return 'fr';
      case JuameaLanguage.en:
        return 'en';
      case JuameaLanguage.sw:
        return 'sw';
    }
  }

  String get shortLabel => code.toUpperCase();

  String get nativeName {
    switch (this) {
      case JuameaLanguage.fr:
        return 'Français';
      case JuameaLanguage.en:
        return 'English';
      case JuameaLanguage.sw:
        return 'Kiswahili';
    }
  }

  String get regionTag {
    switch (this) {
      case JuameaLanguage.fr:
        return "Afrique de l'Est";
      case JuameaLanguage.en:
        return 'East Africa';
      case JuameaLanguage.sw:
        return 'Afrika Mashariki';
    }
  }

  String get ttsLocale {
    switch (this) {
      case JuameaLanguage.fr:
        return 'fr-FR';
      case JuameaLanguage.en:
        return 'en-US';
      case JuameaLanguage.sw:
        return 'sw-KE';
    }
  }

  String get sttLocalePrefix => code;

  static JuameaLanguage fromCode(String? raw) {
    final normalized = (raw ?? 'fr').trim().toLowerCase();
    switch (normalized) {
      case 'en':
        return JuameaLanguage.en;
      case 'sw':
        return JuameaLanguage.sw;
      case 'fr':
      default:
        return JuameaLanguage.fr;
    }
  }
}
