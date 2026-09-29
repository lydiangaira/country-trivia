/// Data model representing a country with its name and ISO code.
class CountryModel {
  /// Common name of the country.
  final String name;

  /// ISO 3166-1 alpha-2 code (used for flag URL construction).
  final String cca2;

  const CountryModel({required this.name, required this.cca2});

  /// Creates a CountryModel from JSON.
  ///
  /// Expects JSON structure from REST Countries API:
  /// ```json
  /// { "name": { "common": "United States" }, "cca2": "US" }
  /// ```
  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      name: json['name']['common'] as String,
      cca2: json['cca2'] as String,
    );
  }

  /// Returns the flag image URL for this country.
  String get flagUrl => 'https://flagcdn.com/w320/${cca2.toLowerCase()}.png';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          cca2 == other.cca2;

  @override
  int get hashCode => name.hashCode ^ cca2.hashCode;

  @override
  String toString() => 'CountryModel(name: $name, cca2: $cca2)';
}
