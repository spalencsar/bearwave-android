import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/radio_station.dart';
import '../services/station_artwork_service.dart';
import '../theme/bearwave_theme.dart';

const int minimumUsableStationLogoPixels = 64;

bool isUsableStationLogo({
  required int width,
  required int height,
  int minimumPixels = minimumUsableStationLogoPixels,
  bool requireSquare = false,
}) {
  if (math.min(width, height) < minimumPixels) {
    return false;
  }
  if (!requireSquare) {
    return true;
  }
  final ratio = width / height;
  return ratio >= 0.75 && ratio <= 1.33;
}

String stationInitials(String stationName) {
  final words = stationName
      .trim()
      .split(RegExp(r'[^A-Za-zÀ-ÖØ-öø-ÿ0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) {
    return 'BW';
  }
  if (words.length > 1) {
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  final word = words.first;
  return word.substring(0, math.min(2, word.length)).toUpperCase();
}

class StationLogo extends StatefulWidget {
  final RadioStation station;
  final double borderRadius;
  final BoxFit fit;
  final int minimumPixels;

  const StationLogo({
    super.key,
    required this.station,
    this.borderRadius = 12,
    this.fit = BoxFit.contain,
    this.minimumPixels = minimumUsableStationLogoPixels,
  });

  @override
  State<StationLogo> createState() => _StationLogoState();
}

class _StationLogoState extends State<StationLogo> {
  String? _resolutionKey;
  String? _resolvedUrl;
  int _resolutionRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveLogoIfNeeded();
  }

  @override
  void didUpdateWidget(covariant StationLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveLogoIfNeeded();
  }

  void _resolveLogoIfNeeded() {
    final key =
        '${widget.station.favicon}|${widget.station.homepage}|${widget.minimumPixels}';
    if (key == _resolutionKey) {
      return;
    }

    _resolutionKey = key;
    _resolvedUrl = null;
    final revision = ++_resolutionRevision;
    final configuration = createLocalImageConfiguration(context);
    _resolveLogo(revision, configuration, widget.station);
  }

  Future<void> _resolveLogo(
    int revision,
    ImageConfiguration configuration,
    RadioStation station,
  ) async {
    final triedUrls = <String>{};
    final favicon = Uri.tryParse(station.favicon ?? '');
    if (favicon != null &&
        (favicon.scheme == 'http' || favicon.scheme == 'https')) {
      final candidate = StationArtworkCandidate(uri: favicon, priority: 5000);
      if (await _candidateIsUsable(candidate, configuration)) {
        _finishResolution(revision, favicon.toString());
        return;
      }
      triedUrls.add(favicon.toString());
    }

    final discovered = await StationArtworkService.instance.discover(station);
    final candidates = <StationArtworkCandidate>[
      ...discovered.take(6),
      if (googleFaviconUri(station.homepage) case final googleUri?)
        StationArtworkCandidate(uri: googleUri, priority: 0),
    ];

    for (final candidate in candidates) {
      if (!mounted || revision != _resolutionRevision) {
        return;
      }
      if (!triedUrls.add(candidate.uri.toString())) {
        continue;
      }
      if (await _candidateIsUsable(candidate, configuration)) {
        _finishResolution(revision, candidate.uri.toString());
        return;
      }
    }

    _finishResolution(revision, null);
  }

  Future<bool> _candidateIsUsable(
    StationArtworkCandidate candidate,
    ImageConfiguration configuration,
  ) async {
    final provider = CachedNetworkImageProvider(candidate.uri.toString());
    final stream = provider.resolve(configuration);
    final completer = Completer<ImageInfo?>();
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(info);
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );
    stream.addListener(listener);

    final info = await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        stream.removeListener(listener);
        return null;
      },
    );
    if (info == null) {
      return false;
    }
    return isUsableStationLogo(
      width: info.image.width,
      height: info.image.height,
      minimumPixels: widget.minimumPixels,
      requireSquare: candidate.requireSquare,
    );
  }

  void _finishResolution(int revision, String? url) {
    if (!mounted || revision != _resolutionRevision) {
      return;
    }
    setState(() {
      _resolvedUrl = url;
    });
  }

  @override
  void dispose() {
    _resolutionRevision++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: _resolvedUrl != null
          ? CachedNetworkImage(
              imageUrl: _resolvedUrl!,
              fit: widget.fit,
              memCacheWidth: 600,
              errorWidget: (context, imageUrl, error) =>
                  _StationInitials(stationName: widget.station.name),
            )
          : _StationInitials(stationName: widget.station.name),
    );
  }
}

class _StationInitials extends StatelessWidget {
  final String stationName;

  const _StationInitials({required this.stationName});

  static const List<List<Color>> _gradients = [
    [BearWaveTheme.spaceDeepBlue, BearWaveTheme.accentVariant],
    [BearWaveTheme.bgB, BearWaveTheme.spaceLightBlue],
    [BearWaveTheme.panel, BearWaveTheme.accent],
    [BearWaveTheme.spaceDark, BearWaveTheme.accentVariant],
  ];

  @override
  Widget build(BuildContext context) {
    final hash = stationName.codeUnits.fold<int>(
      0,
      (value, codeUnit) => ((value * 31) + codeUnit) & 0x7fffffff,
    );
    final colors = _gradients[hash % _gradients.length];

    return Semantics(
      image: true,
      label: stationName,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final fontSize = shortestSide.isFinite
                ? (shortestSide * 0.34).clamp(18.0, 56.0).toDouble()
                : 32.0;
            return Center(
              child: Text(
                stationInitials(stationName),
                style: TextStyle(
                  color: BearWaveTheme.textMain,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  shadows: const [
                    Shadow(
                      color: BearWaveTheme.spaceDark,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
