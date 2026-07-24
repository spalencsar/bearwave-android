import 'package:bearwave/l10n/country_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns German country names for German BearWave', () {
    expect(
      CountryNames.localizedName(
        countryCode: 'DE',
        languageCode: 'de',
        fallbackName: 'Germany',
      ),
      'Deutschland',
    );
    expect(
      CountryNames.localizedName(
        countryCode: 'AE',
        languageCode: 'de-DE',
        fallbackName: 'The United Arab Emirates',
      ),
      'Vereinigte Arabische Emirate',
    );
  });

  test('returns Dutch country names for Dutch BearWave', () {
    expect(
      CountryNames.localizedName(
        countryCode: 'DE',
        languageCode: 'nl',
        fallbackName: 'Germany',
      ),
      'Duitsland',
    );
  });

  test('keeps API names for English and unknown country codes', () {
    expect(
      CountryNames.localizedName(
        countryCode: 'DE',
        languageCode: 'en',
        fallbackName: 'Germany',
      ),
      'Germany',
    );
    expect(
      CountryNames.localizedName(
        countryCode: 'XX',
        languageCode: 'de',
        fallbackName: 'Example country',
      ),
      'Example country',
    );
  });
}
