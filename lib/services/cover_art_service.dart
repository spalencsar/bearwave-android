import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CoverArtService {
  static const String _baseUrl = 'https://itunes.apple.com/search';

  /// Fetches cover art for a given metadata string (e.g. "Artist - Song").
  /// Returns the URL of the cover art if found, otherwise null.
  Future<String?> fetchCoverArt(String metadata, String quality) async {
    // Basic cleanup of metadata
    final cleanQuery = _cleanMetadata(metadata);
    if (cleanQuery.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl?term=${Uri.encodeComponent(cleanQuery)}&entity=song&limit=1');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['resultCount'] != null && data['resultCount'] > 0) {
          final result = data['results'][0];
          String artworkUrl = result['artworkUrl100'];

          // iTunes returns 100x100 by default. Let's replace it based on quality preference.
          if (artworkUrl.isNotEmpty) {
            switch (quality) {
              case 'high':
                return artworkUrl.replaceAll('100x100bb.jpg', '500x500bb.jpg');
              case 'medium':
                return artworkUrl.replaceAll('100x100bb.jpg', '250x250bb.jpg');
              case 'low':
              default:
                return artworkUrl;
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors (e.g. network timeout), just return null so we fallback to station logo
      debugPrint('Error fetching cover art: $e');
    }
    
    return null;
  }

  /// Tries to clean up typical radio stream metadata which might contain noise.
  String _cleanMetadata(String metadata) {
    // Remove typical prefixes some stations add
    String cleaned = metadata.replaceAll(RegExp(r'^(Now Playing:|Now:|Playing:)\s*', caseSensitive: false), '');
    // Remove content inside brackets/parentheses that might confuse the search
    cleaned = cleaned.replaceAll(RegExp(r'\[.*?\]|\(.*?\)', dotAll: true), '');
    return cleaned.trim();
  }
}
