class NowPlayingState {
  int _sourceRevision = 0;
  int _artworkRevision = 0;
  String? _staleTitle;

  int get sourceRevision => _sourceRevision;

  void beginSource(String? previousTitle) {
    _sourceRevision++;
    _artworkRevision++;
    _staleTitle = _normalize(previousTitle);
  }

  void markNoMetadata(String? previousTitle) {
    _artworkRevision++;
    _staleTitle = _normalize(previousTitle) ?? _staleTitle;
  }

  bool shouldAcceptTitle(String? title) {
    final normalizedTitle = _normalize(title);
    if (normalizedTitle == null || normalizedTitle == _staleTitle) {
      return false;
    }

    _staleTitle = null;
    return true;
  }

  int beginArtworkRequest() {
    _artworkRevision++;
    return _artworkRevision;
  }

  void cancelArtworkRequests() {
    _artworkRevision++;
  }

  bool isArtworkRequestCurrent({
    required int artworkRevision,
    required int sourceRevision,
  }) {
    return artworkRevision == _artworkRevision &&
        sourceRevision == _sourceRevision;
  }

  static String? _normalize(String? title) {
    final normalized = title?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
