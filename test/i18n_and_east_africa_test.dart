import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:juamea/core/core.dart';
import 'package:juamea/data/datasources/sqlite_helper.dart';
import 'package:juamea/domain/entities/eac_country_profile.dart';
import 'package:juamea/presentation/bloc/bloc.dart';

void main() {
  tearDown(() async {
    await SQLiteHelper.instance.setSelectedLanguageCode('fr');
  });

  group('Juamea East Africa Regional Identity & FR/EN/SW i18n', () {
    test('UI & PDF service use East Africa identity with zero hardcoded DRC-only strings', () {
      final initSrc = File('lib/presentation/pages/initialization_screen.dart').readAsStringSync();
      final homeSrc = File('lib/presentation/pages/home_page.dart').readAsStringSync();
      final histSrc = File('lib/presentation/pages/diagnostics_history_page.dart').readAsStringSync();
      final pdfSrc = File('lib/core/services/pdf_report_service.dart').readAsStringSync();

      expect(initSrc, isNot(contains("Est de la RDC")));
      expect(homeSrc, isNot(contains('Bukavu, Sud-Kivu, RDC')));
      expect(histSrc, isNot(contains('Bukavu, Sud-Kivu, RDC')));
      expect(pdfSrc, isNot(contains('Bukavu, Sud-Kivu, RDC')));
    });

    test('All 6 East African countries provide FR, EN, and SW localized metadata', () {
      expect(EacCountryProfile.supportedCountries.length, 6);
      for (final country in EacCountryProfile.supportedCountries) {
        for (final lang in JuameaLanguage.values) {
          expect(country.fullName(lang), isNotEmpty);
          expect(country.rainfallSummary(lang), isNotEmpty);
          expect(country.reportLocation(lang), contains(lang.regionTag));
        }
      }
      final ke = EacCountryProfile.byCode('KE');
      expect(ke.narsInstitute, 'KALRO');
      expect(ke.reportLocation(JuameaLanguage.en), contains('East Africa'));
      expect(ke.reportLocation(JuameaLanguage.sw), contains('Afrika Mashariki'));
    });

    test('JuameaStrings supports complete FR, EN, and SW translations', () {
      final fr = JuameaStrings.of(JuameaLanguage.fr);
      final en = JuameaStrings.of(JuameaLanguage.en);
      final sw = JuameaStrings.of(JuameaLanguage.sw);

      expect(fr.initSubtitle, contains("Afrique de l'Est"));
      expect(en.initSubtitle, contains('East Africa'));
      expect(sw.initSubtitle, contains('Afrika Mashariki'));

      expect(fr.navHome, 'Accueil');
      expect(en.navHome, 'Home');
      expect(sw.navHome, 'Nyumbani');

      expect(isJuameaMissingModelMessage(fr.chatMissingModelPrompt), isTrue);
      expect(isJuameaMissingModelMessage(en.chatMissingModelPrompt), isTrue);
      expect(isJuameaMissingModelMessage(sw.chatMissingModelPrompt), isTrue);
    });

    test('LocaleCubit switches cleanly between FR, EN, and SW', () async {
      final cubit = LocaleCubit();
      expect(cubit.state.language, JuameaLanguage.fr);

      await cubit.setLanguage(JuameaLanguage.en);
      expect(cubit.state.language, JuameaLanguage.en);
      expect(cubit.state.strings.takePhotoTitle, 'Take a photo');
      expect(SQLiteHelper.currentLanguageCode, 'en');

      await cubit.setLanguage(JuameaLanguage.sw);
      expect(cubit.state.language, JuameaLanguage.sw);
      expect(cubit.state.strings.takePhotoTitle, 'Piga picha');
      expect(SQLiteHelper.currentLanguageCode, 'sw');

      await cubit.close();
    });
  });
}
