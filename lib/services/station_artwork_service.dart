import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/radio_station.dart';

class StationArtworkCandidate {
  final Uri uri;
  final bool requireSquare;
  final int priority;

  const StationArtworkCandidate({
    required this.uri,
    required this.priority,
    this.requireSquare = false,
  });
}

class StationArtworkPage {
  final List<StationArtworkCandidate> candidates;
  final List<Uri> manifestUris;

  const StationArtworkPage({
    required this.candidates,
    required this.manifestUris,
  });
}

class StationArtworkService {
  static final StationArtworkService instance = StationArtworkService();

  static const Duration _requestTimeout = Duration(seconds: 5);
  static const int _maximumHtmlBytes = 512 * 1024;
  static const int _maximumManifestBytes = 256 * 1024;
  static const int _maximumConcurrentDiscoveries = 4;

  final http.Client _client;
  final Map<String, Future<List<StationArtworkCandidate>>> _discoveryCache = {};
  final Queue<Completer<void>> _requestQueue = Queue();
  int _activeDiscoveries = 0;

  StationArtworkService({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<StationArtworkCandidate>> discover(RadioStation station) {
    final homepage = _parseRemoteUri(station.homepage);
    if (homepage == null) {
      return Future.value(const []);
    }

    return _discoveryCache.putIfAbsent(
      homepage.toString(),
      () => _withRequestSlot(() => _discover(homepage)),
    );
  }

  Future<T> _withRequestSlot<T>(Future<T> Function() action) async {
    if (_activeDiscoveries >= _maximumConcurrentDiscoveries) {
      final ready = Completer<void>();
      _requestQueue.add(ready);
      await ready.future;
    }

    _activeDiscoveries++;
    try {
      return await action();
    } finally {
      _activeDiscoveries--;
      if (_requestQueue.isNotEmpty) {
        _requestQueue.removeFirst().complete();
      }
    }
  }

  Future<List<StationArtworkCandidate>> _discover(Uri homepage) async {
    final pageDownload = await _downloadText(
      homepage,
      maximumBytes: _maximumHtmlBytes,
    );
    if (pageDownload == null) {
      return const [];
    }

    final page = parseStationArtworkHtml(
      pageDownload.text,
      pageDownload.finalUri,
    );
    final candidates = [
      ...page.candidates,
      if (_resolveRemoteUri(pageDownload.finalUri, '/favicon.ico')
          case final defaultFavicon?)
        StationArtworkCandidate(uri: defaultFavicon, priority: 200),
    ];

    for (final manifestUri in page.manifestUris.take(1)) {
      final manifestDownload = await _downloadText(
        manifestUri,
        maximumBytes: _maximumManifestBytes,
      );
      if (manifestDownload == null) {
        continue;
      }
      candidates.addAll(
        parseStationArtworkManifest(
          manifestDownload.text,
          manifestDownload.finalUri,
        ),
      );
    }

    final byUrl = <String, StationArtworkCandidate>{};
    for (final candidate in candidates) {
      final key = candidate.uri.toString();
      final existing = byUrl[key];
      if (existing == null || candidate.priority > existing.priority) {
        byUrl[key] = candidate;
      }
    }

    final result = byUrl.values.toList()
      ..sort((first, second) => second.priority.compareTo(first.priority));
    return List.unmodifiable(result);
  }

  Future<_DownloadedText?> _downloadText(
    Uri uri, {
    required int maximumBytes,
  }) async {
    if (!_isAllowedRemoteUri(uri)) {
      return null;
    }

    try {
      var currentUri = uri;
      http.StreamedResponse? response;
      for (var redirectCount = 0; redirectCount <= 4; redirectCount++) {
        final request = http.Request('GET', currentUri)
          ..followRedirects = false
          ..headers.addAll(const {
            'User-Agent': 'BearWave/1.0',
            'Accept': 'text/html,application/manifest+json,application/json',
          });
        response = await _client.send(request).timeout(_requestTimeout);
        if (!_isRedirect(response.statusCode)) {
          break;
        }

        final location = response.headers['location'];
        await response.stream.drain<void>();
        if (location == null || redirectCount == 4) {
          return null;
        }
        final redirectUri = _resolveRemoteUri(currentUri, location);
        if (redirectUri == null) {
          return null;
        }
        currentUri = redirectUri;
        response = null;
      }

      if (response == null) {
        return null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(_requestTimeout)) {
        final remaining = maximumBytes - bytes.length;
        if (remaining <= 0) {
          break;
        }
        bytes.add(
          chunk.length <= remaining ? chunk : chunk.sublist(0, remaining),
        );
        if (chunk.length > remaining) {
          break;
        }
      }

      return _DownloadedText(
        text: utf8.decode(bytes.takeBytes(), allowMalformed: true),
        finalUri: response.request?.url ?? uri,
      );
    } catch (_) {
      return null;
    }
  }
}

bool _isRedirect(int statusCode) {
  return statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;
}

StationArtworkPage parseStationArtworkHtml(String html, Uri baseUri) {
  final headEnd = html.toLowerCase().indexOf('</head>');
  final searchableHtml = headEnd >= 0 ? html.substring(0, headEnd) : html;
  final candidates = <StationArtworkCandidate>[];
  final manifests = <Uri>[];

  for (final match in RegExp(
    r'<link\b[^>]*>',
    caseSensitive: false,
  ).allMatches(searchableHtml)) {
    final attributes = _parseAttributes(match.group(0)!);
    final rel = attributes['rel']?.toLowerCase() ?? '';
    final href = attributes['href'];
    final uri = _resolveRemoteUri(baseUri, href);
    if (uri == null) {
      continue;
    }

    if (rel.split(RegExp(r'\s+')).contains('manifest')) {
      manifests.add(uri);
      continue;
    }

    final sizeScore = _iconSizeScore(attributes['sizes']);
    if (rel.contains('apple-touch-icon')) {
      candidates.add(
        StationArtworkCandidate(uri: uri, priority: 4000 + sizeScore),
      );
    } else if (rel.split(RegExp(r'\s+')).contains('icon')) {
      candidates.add(
        StationArtworkCandidate(uri: uri, priority: 3000 + sizeScore),
      );
    }
  }

  for (final match in RegExp(
    r'<meta\b[^>]*>',
    caseSensitive: false,
  ).allMatches(searchableHtml)) {
    final attributes = _parseAttributes(match.group(0)!);
    final property = (attributes['property'] ?? attributes['name'])
        ?.toLowerCase();
    if (property != 'og:image' && property != 'og:image:url') {
      continue;
    }
    final uri = _resolveRemoteUri(baseUri, attributes['content']);
    if (uri != null) {
      candidates.add(
        StationArtworkCandidate(uri: uri, priority: 100, requireSquare: true),
      );
    }
  }

  candidates.sort((first, second) => second.priority.compareTo(first.priority));
  return StationArtworkPage(
    candidates: List.unmodifiable(candidates),
    manifestUris: List.unmodifiable(manifests),
  );
}

List<StationArtworkCandidate> parseStationArtworkManifest(
  String manifestJson,
  Uri baseUri,
) {
  try {
    final decoded = jsonDecode(manifestJson);
    if (decoded is! Map<String, dynamic> || decoded['icons'] is! List) {
      return const [];
    }

    final candidates = <StationArtworkCandidate>[];
    for (final entry in decoded['icons'] as List) {
      if (entry is! Map) {
        continue;
      }
      final source = entry['src'];
      final uri = _resolveRemoteUri(baseUri, source is String ? source : null);
      if (uri == null) {
        continue;
      }
      final sizes = entry['sizes'];
      candidates.add(
        StationArtworkCandidate(
          uri: uri,
          priority: 3500 + _iconSizeScore(sizes is String ? sizes : null),
        ),
      );
    }
    candidates.sort(
      (first, second) => second.priority.compareTo(first.priority),
    );
    return List.unmodifiable(candidates);
  } catch (_) {
    return const [];
  }
}

Uri? googleFaviconUri(String? homepage) {
  final homepageUri = _parseRemoteUri(homepage);
  if (homepageUri == null) {
    return null;
  }
  final encodedUrl = Uri.encodeComponent(homepageUri.toString());
  return Uri.parse(
    'https://t0.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=$encodedUrl&size=256',
  );
}

Map<String, String> _parseAttributes(String tag) {
  final attributes = <String, String>{};
  final pattern = RegExp(
    r'''([:\w-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+))''',
  );
  for (final match in pattern.allMatches(tag)) {
    final name = match.group(1)!.toLowerCase();
    final value = match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
    attributes[name] = _decodeHtmlAttribute(value);
  }
  return attributes;
}

String _decodeHtmlAttribute(String value) {
  return value
      .replaceAll('&amp;', '&')
      .replaceAll('&#38;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}

int _iconSizeScore(String? sizes) {
  if (sizes == null) {
    return 0;
  }
  var largest = 0;
  for (final match in RegExp(
    r'(\d+)\s*x\s*(\d+)',
    caseSensitive: false,
  ).allMatches(sizes)) {
    final width = int.tryParse(match.group(1)!) ?? 0;
    final height = int.tryParse(match.group(2)!) ?? 0;
    final shorterEdge = width < height ? width : height;
    if (shorterEdge > largest) {
      largest = shorterEdge;
    }
  }
  return largest.clamp(0, 999);
}

Uri? _resolveRemoteUri(Uri baseUri, String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  try {
    final uri = baseUri.resolve(value.trim());
    return _isAllowedRemoteUri(uri) ? uri : null;
  } catch (_) {
    return null;
  }
}

Uri? _parseRemoteUri(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(value.trim());
  return uri != null && _isAllowedRemoteUri(uri) ? uri : null;
}

bool _isAllowedRemoteUri(Uri uri) {
  if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
    return false;
  }

  final host = uri.host.toLowerCase();
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local')) {
    return false;
  }

  final address = InternetAddress.tryParse(host);
  if (address == null) {
    return true;
  }
  if (address.isLoopback || address.isLinkLocal) {
    return false;
  }

  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return !(bytes[0] == 10 ||
        (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
        (bytes[0] == 192 && bytes[1] == 168) ||
        (bytes[0] == 169 && bytes[1] == 254));
  }
  return !((bytes[0] & 0xfe) == 0xfc);
}

class _DownloadedText {
  final String text;
  final Uri finalUri;

  const _DownloadedText({required this.text, required this.finalUri});
}
