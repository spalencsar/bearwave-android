import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/radio_station.dart';
import '../models/country.dart';

class RadioBrowserApi {
  static const String userAgent = 'BearWave/1.0';
  static const String baseUrl = 'https://all.api.radio-browser.info/json';

  Future<List<RadioStation>> getTopStations({int limit = 50, int offset = 0}) async {
    return _getStations('/stations/topvote/$limit?offset=$offset');
  }

  Future<List<RadioStation>> getGermanStations({int limit = 50, int offset = 0}) async {
    return _getStations('/stations/bycountrycodeexact/DE?limit=$limit&order=votes&reverse=true&offset=$offset');
  }

  Future<List<RadioStation>> getDutchStations({int limit = 50, int offset = 0}) async {
    return _getStations('/stations/bycountrycodeexact/NL?limit=$limit&order=votes&reverse=true&offset=$offset');
  }

  Future<List<RadioStation>> getByCountryCode(String countryCode, {int limit = 50, int offset = 0}) async {
    return _getStations('/stations/bycountrycodeexact/${countryCode.toUpperCase()}?limit=$limit&order=votes&reverse=true&offset=$offset');
  }

  Future<List<RadioStation>> getByTag(String tag, {int limit = 50, int offset = 0}) async {
    final encodedTag = Uri.encodeComponent(tag);
    return _getStations('/stations/bytag/$encodedTag?limit=$limit&order=votes&reverse=true&offset=$offset');
  }

  Future<List<RadioStation>> getWorldStations({int limit = 50, int offset = 0}) async {
    return _getStations('/stations?hidebroken=true&limit=$limit&order=votes&reverse=true&offset=$offset');
  }

  Future<List<RadioStation>> search(String query, {int limit = 50, int offset = 0}) async {
    final encodedQuery = Uri.encodeComponent(query);
    return _getStations(
      '/stations/search?name=$encodedQuery&hidebroken=true&limit=$limit&order=votes&reverse=true&offset=$offset',
    );
  }

  Future<List<Country>> getCountries() async {
    final url = Uri.parse('$baseUrl/countries');
    final response = await http.get(
      url,
      headers: {'User-Agent': userAgent},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to load countries: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body);
    return data
        .map((json) => Country.fromJson(json as Map<String, dynamic>))
        .where((country) => country.name.isNotEmpty && country.stationCount > 0)
        .toList();
  }

  Future<List<RadioStation>> _getStations(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(
      url,
      headers: {'User-Agent': userAgent},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to load stations: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body);
    return data
        .map((json) => RadioStation.fromJson(json as Map<String, dynamic>))
        .where((station) => station.name.isNotEmpty && station.urlResolved.isNotEmpty)
        .toList();
  }
}