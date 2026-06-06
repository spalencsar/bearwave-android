class Country {
  final String name;
  final String code;
  final int stationCount;

  Country({
    required this.name,
    required this.code,
    required this.stationCount,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String? ?? '',
      code: json['iso_3166_1'] as String? ?? '',
      stationCount: json['stationcount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'stationcount': stationCount,
    };
  }
}