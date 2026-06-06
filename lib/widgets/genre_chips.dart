import 'package:flutter/material.dart';
import '../theme/bearwave_theme.dart';

class GenreChip {
  final String name;
  final String tag;
  final IconData icon;

  const GenreChip({required this.name, required this.tag, required this.icon});
}

class GenreChips extends StatelessWidget {
  final List<GenreChip> genres;
  final String? selectedTag;
  final ValueChanged<String> onGenreTap;

  const GenreChips({
    super.key,
    required this.genres,
    this.selectedTag,
    required this.onGenreTap,
  });

  static const List<GenreChip> defaultGenres = [
    GenreChip(name: 'Pop', tag: 'pop', icon: Icons.music_note),
    GenreChip(name: 'Rock', tag: 'rock', icon: Icons.music_note),
    GenreChip(name: 'Electronic', tag: 'electronic', icon: Icons.piano),
    GenreChip(name: 'Classical', tag: 'classical', icon: Icons.music_note),
    GenreChip(name: 'Jazz', tag: 'jazz', icon: Icons.music_note),
    GenreChip(name: 'Metal', tag: 'metal', icon: Icons.music_note),
    GenreChip(name: 'Hip Hop', tag: 'hiphop', icon: Icons.mic),
    GenreChip(name: 'Chillout', tag: 'chillout', icon: Icons.music_note),
    GenreChip(name: 'News / Talk', tag: 'news', icon: Icons.radio),
    GenreChip(name: 'Soundtracks', tag: 'soundtrack', icon: Icons.movie),
    GenreChip(name: 'Ambient', tag: 'ambient', icon: Icons.music_note),
    GenreChip(name: 'Blues / Soul', tag: 'blues', icon: Icons.music_note),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((genre) {
        final isSelected = selectedTag == genre.tag;
        return GestureDetector(
          onTap: () => onGenreTap(genre.tag),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? BearWaveTheme.accent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? BearWaveTheme.accent
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  genre.icon,
                  size: 16,
                  color: isSelected
                      ? BearWaveTheme.accent
                      : BearWaveTheme.textMain,
                ),
                const SizedBox(width: 6),
                Text(
                  genre.name,
                  style: TextStyle(
                    color: isSelected
                        ? BearWaveTheme.accent
                        : BearWaveTheme.textMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
