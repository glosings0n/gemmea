import 'package:juamea/core/localization/juamea_language.dart';

/// Regional agronomic metadata across East Africa (EAC & Great Lakes: CD, UG, RW, BI, KE, TZ).
class EacCountryProfile {
  final String code;
  final String shortName;
  final String shortNameEn;
  final String fullNameFr;
  final String fullNameEn;
  final String fullNameSw;
  final String narsInstitute;
  final String rainfallRegimeSummary;
  final String rainfallRegimeSummaryEn;
  final String rainfallRegimeSummarySw;

  const EacCountryProfile({
    required this.code,
    required this.shortName,
    required this.shortNameEn,
    required this.fullNameFr,
    required this.fullNameEn,
    required this.fullNameSw,
    required this.narsInstitute,
    required this.rainfallRegimeSummary,
    required this.rainfallRegimeSummaryEn,
    required this.rainfallRegimeSummarySw,
  });

  String shortLabel(JuameaLanguage lang) {
    return lang == JuameaLanguage.fr ? shortName : shortNameEn;
  }

  String fullName(JuameaLanguage lang) {
    switch (lang) {
      case JuameaLanguage.en:
        return fullNameEn;
      case JuameaLanguage.sw:
        return fullNameSw;
      case JuameaLanguage.fr:
        return fullNameFr;
    }
  }

  String rainfallSummary(JuameaLanguage lang) {
    switch (lang) {
      case JuameaLanguage.en:
        return rainfallRegimeSummaryEn;
      case JuameaLanguage.sw:
        return rainfallRegimeSummarySw;
      case JuameaLanguage.fr:
        return rainfallRegimeSummary;
    }
  }

  String reportLocation(JuameaLanguage lang) {
    return '${fullName(lang)} ($narsInstitute) — ${lang.regionTag}';
  }

  static const List<EacCountryProfile> supportedCountries = [
    EacCountryProfile(
      code: 'KE',
      shortName: 'KE',
      shortNameEn: 'KE',
      fullNameFr: 'Kenya',
      fullNameEn: 'Kenya',
      fullNameSw: 'Kenya',
      narsInstitute: 'KALRO',
      rainfallRegimeSummary:
          'Long Rains (mars-mai) et Short Rains (octobre-décembre) ; Push-Pull ICIPE.',
      rainfallRegimeSummaryEn:
          'Long Rains (Mar–May) & Short Rains (Oct–Dec); ICIPE Push-Pull zones.',
      rainfallRegimeSummarySw:
          'Masika (Mac–Mei) na Vuli (Okt–Des); mbinu za Push-Pull za ICIPE.',
    ),
    EacCountryProfile(
      code: 'TZ',
      shortName: 'TZ',
      shortNameEn: 'TZ',
      fullNameFr: 'Tanzanie',
      fullNameEn: 'Tanzania',
      fullNameSw: 'Tanzania',
      narsInstitute: 'TARI',
      rainfallRegimeSummary:
          'Nord/Lac bimodal (Vuli oct-déc, Masika mars-mai) ; Centre/Sud unimodal (Msimu nov-avr).',
      rainfallRegimeSummaryEn:
          'North/Lake bimodal (Vuli Oct–Dec, Masika Mar–May); Central/South unimodal (Msimu Nov–Apr).',
      rainfallRegimeSummarySw:
          'Kaskazini/Ziwa misimu miwili (Vuli Okt–Des, Masika Mac–Mei); Kati/Kusini msimu mmoja (Msimu Nov–Apr).',
    ),
    EacCountryProfile(
      code: 'UG',
      shortName: 'UG',
      shortNameEn: 'UG',
      fullNameFr: 'Ouganda',
      fullNameEn: 'Uganda',
      fullNameSw: 'Uganda',
      narsInstitute: 'NARO',
      rainfallRegimeSummary:
          'Centre/Ouest bimodal (mars-juin, août-nov) ; Nord unimodal (avril-octobre).',
      rainfallRegimeSummaryEn:
          'Central/West bimodal (Mar–Jun, Aug–Nov); Northern unimodal (Apr–Oct).',
      rainfallRegimeSummarySw:
          'Kati/Magharibi misimu miwili (Mac–Jun, Ago–Nov); Kaskazini msimu mmoja (Apr–Okt).',
    ),
    EacCountryProfile(
      code: 'RW',
      shortName: 'RW',
      shortNameEn: 'RW',
      fullNameFr: 'Rwanda',
      fullNameEn: 'Rwanda',
      fullNameSw: 'Rwanda',
      narsInstitute: 'RAB',
      rainfallRegimeSummary:
          'Saison A (sept-janv), Saison B (févr-juin) et Saison C marais (juil-oct).',
      rainfallRegimeSummaryEn:
          'Season A (Sep–Jan), Season B (Feb–Jun), and Season C marshlands (Jul–Oct).',
      rainfallRegimeSummarySw:
          'Msimu A (Sep–Jan), Msimu B (Feb–Jun) na Msimu C mabondeni (Jul–Okt).',
    ),
    EacCountryProfile(
      code: 'BI',
      shortName: 'BI',
      shortNameEn: 'BI',
      fullNameFr: 'Burundi',
      fullNameEn: 'Burundi',
      fullNameSw: 'Burundi',
      narsInstitute: 'ISABU',
      rainfallRegimeSummary:
          'Saison A (oct-févr), Saison B (mars-juin) et Saison C bas-fonds (juil-oct).',
      rainfallRegimeSummaryEn:
          'Season A (Oct–Feb), Season B (Mar–Jun), and Season C lowlands (Jul–Oct).',
      rainfallRegimeSummarySw:
          'Msimu A (Okt–Feb), Msimu B (Mac–Jun) na Msimu C mabondeni (Jul–Okt).',
    ),
    EacCountryProfile(
      code: 'CD',
      shortName: 'RDC',
      shortNameEn: 'DRC',
      fullNameFr: 'RD Congo',
      fullNameEn: 'DR Congo',
      fullNameSw: 'DR Kongo',
      narsInstitute: 'INERA',
      rainfallRegimeSummary:
          'Kivu/Ituri bimodal (Saison A sept-janv, B mars-juil) ; Grand Katanga unimodal (nov-avr).',
      rainfallRegimeSummaryEn:
          'Kivu/Ituri bimodal (Season A Sep–Jan, B Mar–Jul); Katanga unimodal (Nov–Apr).',
      rainfallRegimeSummarySw:
          'Kivu/Ituri misimu miwili (Msimu A Sep–Jan, B Mac–Jul); Katanga msimu mmoja (Nov–Apr).',
    ),
  ];

  static EacCountryProfile byCode(String? code) {
    final normalized = (code ?? 'CD').trim().toUpperCase();
    for (final p in supportedCountries) {
      if (p.code == normalized) return p;
    }
    return supportedCountries.first;
  }
}
