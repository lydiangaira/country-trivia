import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country_model.dart';
import '../../core/constants/api_constants.dart';

/// HTTP client for fetching country data from the REST Countries API.
class CountryApi {
  final http.Client _client;

  /// Creates a CountryApi with an optional HTTP client for testing.
  CountryApi({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches all countries from the REST Countries API.
  ///
  /// Returns a list of CountryModel instances.
  /// Throws an exception if the request fails or returns a non-200 status.
  Future<List<CountryModel>> fetchAllCountries() async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.countriesBaseUrl}${ApiConstants.allCountriesEndpoint}'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch countries: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;

    return jsonList
        .where((json) => _isValidCountryJson(json as Map<String, dynamic>))
        .map((json) => CountryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Validates that a country JSON entry has the required fields.
  bool _isValidCountryJson(Map<String, dynamic> json) {
    final name = json['name'];
    final cca2 = json['cca2'];
    return name is Map<String, dynamic> &&
        name['common'] is String &&
        (name['common'] as String).isNotEmpty &&
        cca2 is String &&
        cca2.isNotEmpty;
  }
}
