import 'package:bearwave/services/now_playing_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NowPlayingState', () {
    test('rejects metadata retained from the previous source', () {
      final state = NowPlayingState();

      state.beginSource('Old Artist - Old Title');

      expect(state.shouldAcceptTitle('Old Artist - Old Title'), isFalse);
      expect(state.shouldAcceptTitle('New Artist - New Title'), isTrue);
    });

    test('treats null and blank metadata as unavailable', () {
      final state = NowPlayingState();

      state.beginSource(null);

      expect(state.shouldAcceptTitle(null), isFalse);
      expect(state.shouldAcceptTitle('   '), isFalse);
    });

    test('invalidates artwork requests on source change', () {
      final state = NowPlayingState();
      state.beginSource(null);
      final sourceRevision = state.sourceRevision;
      final artworkRevision = state.beginArtworkRequest();

      state.beginSource('Old Artist - Old Title');

      expect(
        state.isArtworkRequestCurrent(
          artworkRevision: artworkRevision,
          sourceRevision: sourceRevision,
        ),
        isFalse,
      );
    });

    test('invalidates artwork when metadata is cleared', () {
      final state = NowPlayingState();
      state.beginSource(null);
      final sourceRevision = state.sourceRevision;
      final artworkRevision = state.beginArtworkRequest();

      state.markNoMetadata('Artist - Title');

      expect(
        state.isArtworkRequestCurrent(
          artworkRevision: artworkRevision,
          sourceRevision: sourceRevision,
        ),
        isFalse,
      );
      expect(state.shouldAcceptTitle('Artist - Title'), isFalse);
    });

    test('only the latest artwork request remains current', () {
      final state = NowPlayingState();
      state.beginSource(null);
      final sourceRevision = state.sourceRevision;
      final firstArtworkRevision = state.beginArtworkRequest();
      final secondArtworkRevision = state.beginArtworkRequest();

      expect(
        state.isArtworkRequestCurrent(
          artworkRevision: firstArtworkRevision,
          sourceRevision: sourceRevision,
        ),
        isFalse,
      );
      expect(
        state.isArtworkRequestCurrent(
          artworkRevision: secondArtworkRevision,
          sourceRevision: sourceRevision,
        ),
        isTrue,
      );
    });
  });
}
