import 'package:flutter/material.dart';
import '../theme/bearwave_theme.dart';

class BearWaveSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearch;
  final FocusNode? focusNode;

  const BearWaveSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search stations (name, genre, country)',
    this.onChanged,
    this.onSearch,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: BearWaveTheme.textMuted),
              prefixIcon: const Icon(Icons.search, color: BearWaveTheme.textMuted),
              suffixIcon: controller != null && controller!.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: BearWaveTheme.textMuted),
                      onPressed: () {
                        controller!.clear();
                        onChanged?.call('');
                      },
                    )
                  : null,
            ),
            onChanged: onChanged,
            onSubmitted: (_) => onSearch?.call(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onSearch,
          child: const Text('Search'),
        ),
      ],
    );
  }
}