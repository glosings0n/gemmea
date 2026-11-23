import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:juamea/core/core.dart';
import 'package:juamea/data/datasources/sqlite_helper.dart';

class LocaleState {
  final JuameaLanguage language;

  const LocaleState(this.language);

  JuameaStringsData get strings => JuameaStrings.of(language);
}

class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit() : super(LocaleState(JuameaLanguageX.fromCode(SQLiteHelper.currentLanguageCode)));

  Future<void> _syncVoiceLocale(JuameaLanguage lang) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      await VoiceService.instance.setLanguage(lang);
    } catch (_) {}
  }

  Future<void> loadSavedLanguage() async {
    final code = await SQLiteHelper.instance.getSelectedLanguageCode();
    final lang = JuameaLanguageX.fromCode(code);
    await _syncVoiceLocale(lang);
    emit(LocaleState(lang));
  }

  Future<void> setLanguage(JuameaLanguage language) async {
    await SQLiteHelper.instance.setSelectedLanguageCode(language.code);
    await _syncVoiceLocale(language);
    emit(LocaleState(language));
  }
}
