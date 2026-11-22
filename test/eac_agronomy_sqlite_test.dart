import 'package:flutter_test/flutter_test.dart';
import 'package:juamea/data/datasources/sqlite_helper.dart';
import 'package:juamea/data/repositories/chat_repository_impl.dart';
import 'package:juamea/domain/entities/eac_country_profile.dart';

void main() {
  group('Gemmea 6-Country EAC SQLite RAG & Agronomy Calculators', () {
    tearDown(() async {
      SQLiteHelper.instance.setTestEacRunner(null);
      await SQLiteHelper.instance.setSelectedCountryCode('CD');
    });

    test('Covers all 6 EAC/DRC profiles and NARS institutes', () {
      final codes =
          EacCountryProfile.supportedCountries.map((e) => e.code).toSet();
      expect(codes, {'CD', 'UG', 'RW', 'BI', 'KE', 'TZ'});
      expect(EacCountryProfile.byCode('KE').narsInstitute, 'KALRO');
      expect(EacCountryProfile.byCode('TZ').rainfallRegimeSummary,
          contains('Vuli'));
      expect(EacCountryProfile.byCode('CD').rainfallRegimeSummary,
          contains('Katanga'));
    });

    test('SQLiteHelper ranks country-specific EAC records ahead of others',
        () async {
      await SQLiteHelper.instance.setSelectedCountryCode('UG');
      SQLiteHelper.instance.setTestEacRunner((sql, args) async {
        if (sql.contains('MATCH ?')) {
          return [
            {
              'id': 1,
              'country_code': 'CD',
              'region': 'RDC Est',
              'crop_name': 'Manioc',
              'topic': 'CMD RDC INERA',
              'citation': 'INERA RDC (2024)',
              'keywords': 'manioc cmd tme 419',
              'estimated_loss_pct': 55.0,
              'organic_remedy': 'TME 419',
              'content': 'Protocole manioc RDC',
            },
            {
              'id': 2,
              'country_code': 'EAC_ALL',
              'region': 'EAC',
              'crop_name': 'Maïs',
              'topic': 'FAW EAC',
              'citation': 'FAO (2024)',
              'keywords': 'faw neem',
              'estimated_loss_pct': 45.0,
              'organic_remedy': 'Neem',
              'content': 'Protocole FAW',
            },
            {
              'id': 3,
              'country_code': 'UG',
              'region': 'Ouganda',
              'crop_name': 'Manioc & Bananier',
              'topic': 'NARO Ouganda NAROCASS 1',
              'citation': 'NARO Uganda (2024)',
              'keywords': 'ouganda naro narocass cbsd',
              'estimated_loss_pct': 65.0,
              'organic_remedy': 'NAROCASS 1',
              'content': 'Protocole NARO Ouganda',
            },
          ];
        }
        return const [];
      });

      final results =
          await SQLiteHelper.instance.searchFAOKnowledge('manioc narocass');
      expect(results.length, 3);
      expect(results.first['country_code'], 'UG');
      expect(results.first['source_citation'], 'NARO Uganda (2024)');
      expect(results[1]['country_code'], 'EAC_ALL');
    });

    test('ChatRepositoryImpl injects exact AgronomyPlotCalculator figures', () {
      final ctx = ChatRepositoryImpl.buildDeterministicAgronomySupplement(
        'Combien de boutures de manioc pour un champ de 20m x 30m et combien de litres de neem pour 500 m2 ?',
        countryCode: 'KE',
      );
      expect(ctx, contains('KALRO'));
      expect(ctx, contains('600 boutures exactes'));
      expect(ctx, contains('660 avec +10%'));
      expect(ctx, contains('20.0 litres') /* or 20 litres */);
    });
  });
}
