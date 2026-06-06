class RadioStation {
  final String? uuid;
  final String name;
  final String url;
  final String urlResolved;
  final String? homepage;
  final String? favicon;
  final String? country;
  final String? tags;
  final String? codec;
  final int? bitrate;
  final int? votes;
  final bool? isOnline;
  bool isFavorite;

  String? get faviconOrFallbackUrl {
    if (favicon != null && favicon!.startsWith('http')) {
      return favicon;
    }
    if (homepage != null && homepage!.startsWith('http')) {
      final encodedUrl = Uri.encodeComponent(homepage!);
      return 'https://t0.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=$encodedUrl&size=256';
    }
    return null;
  }

  RadioStation({
    this.uuid,
    required this.name,
    required this.url,
    required this.urlResolved,
    this.homepage,
    this.favicon,
    this.country,
    this.tags,
    this.codec,
    this.bitrate,
    this.votes,
    this.isOnline,
    this.isFavorite = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      uuid: json['uuid'] as String?,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      urlResolved: json['url_resolved'] as String? ?? json['url'] as String? ?? '',
      homepage: json['homepage'] as String?,
      favicon: json['favicon'] as String?,
      country: json['country'] as String?,
      tags: json['tags'] as String?,
      codec: json['codec'] as String?,
      bitrate: json['bitrate'] as int?,
      votes: json['votes'] as int?,
      isOnline: json['isOnline'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'url': url,
      'urlResolved': urlResolved,
      'homepage': homepage,
      'favicon': favicon,
      'country': country,
      'tags': tags,
      'codec': codec,
      'bitrate': bitrate,
      'votes': votes,
      'isFavorite': isFavorite,
    };
  }

  factory RadioStation.fromStorageJson(Map<String, dynamic> json) {
    return RadioStation(
      uuid: json['uuid'] as String?,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      urlResolved: json['urlResolved'] as String? ?? '',
      homepage: json['homepage'] as String?,
      favicon: json['favicon'] as String?,
      country: json['country'] as String?,
      tags: json['tags'] as String?,
      codec: json['codec'] as String?,
      bitrate: json['bitrate'] as int?,
      votes: json['votes'] as int?,
      isOnline: json['isOnline'] as bool?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}