/// API endpoints and URL patterns used throughout the app.
class ApiConstants {
  ApiConstants._();

  /// Base URL for the REST Countries API.
  static const String countriesBaseUrl = 'https://restcountries.com/v3.1';

  /// Endpoint to fetch all countries.
  static const String allCountriesEndpoint = '/all';

  /// Base URL for flag images (320px width).
  static const String flagCdnBaseUrl = 'https://flagcdn.com/w320';

  /// Pattern for constructing a flag image URL from an ISO code.
  static String flagUrl(String isoCode) =>
      '$flagCdnBaseUrl/${isoCode.toLowerCase()}.png';
}
