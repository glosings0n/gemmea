/// Regional agronomic metadata across DRC & all East African Community (EAC) zones.
class EacCountryProfile {
  final String code;
  final String shortName;
  final String fullNameFr;
  final String narsInstitute;
  final String rainfallRegimeSummary;

  const EacCountryProfile({
    required this.code,
    required this.shortName,
    required this.fullNameFr,
    required this.narsInstitute,
    required this.rainfallRegimeSummary,
  });

  static const List<EacCountryProfile> supportedCountries = [
    EacCountryProfile(
      code: 'CD',
      shortName: 'RDC',
      fullNameFr: 'RD Congo',
      narsInstitute: 'INERA',
      rainfallRegimeSummary:
          'Kivu/Ituri bimodal (Saison A sept-janv, B mars-juil) ; Grand Katanga unimodal (nov-avr).',
    ),
    EacCountryProfile(
      code: 'UG',
      shortName: 'UG',
      fullNameFr: 'Ouganda',
      narsInstitute: 'NARO',
      rainfallRegimeSummary:
          'Centre/Ouest bimodal (mars-juin, août-nov) ; Nord unimodal (avril-octobre).',
    ),
    EacCountryProfile(
      code: 'RW',
      shortName: 'RW',
      fullNameFr: 'Rwanda',
      narsInstitute: 'RAB',
      rainfallRegimeSummary:
          'Saison A (sept-janv), Saison B (févr-juin) et Saison C marais (juil-oct).',
    ),
    EacCountryProfile(
      code: 'BI',
      shortName: 'BI',
      fullNameFr: 'Burundi',
      narsInstitute: 'ISABU',
      rainfallRegimeSummary:
          'Saison A (oct-févr), Saison B (mars-juin) et Saison C bas-fonds (juil-oct).',
    ),
    EacCountryProfile(
      code: 'KE',
      shortName: 'KE',
      fullNameFr: 'Kenya',
      narsInstitute: 'KALRO',
      rainfallRegimeSummary:
          'Long Rains (mars-mai) et Short Rains (octobre-décembre) ; Push-Pull ICIPE.',
    ),
    EacCountryProfile(
      code: 'TZ',
      shortName: 'TZ',
      fullNameFr: 'Tanzanie',
      narsInstitute: 'TARI',
      rainfallRegimeSummary:
          'Nord/Lac bimodal (Vuli oct-déc, Masika mars-mai) ; Centre/Sud unimodal (Msimu nov-avr).',
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
