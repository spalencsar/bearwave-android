import 'package:flutter/material.dart';
import '../theme/bearwave_theme.dart';
import '../l10n/translations.dart';

class AddStationDialog extends StatefulWidget {
  final Function(String name, String url, String country) onAdd;

  const AddStationDialog({super.key, required this.onAdd});

  @override
  State<AddStationDialog> createState() => _AddStationDialogState();
}

class _AddStationDialogState extends State<AddStationDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BearWaveTheme.panel,
      title: Text(
        Translations.get(context, 'addStation'),
        style: const TextStyle(color: BearWaveTheme.textMain),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: Translations.get(context, 'stationName'),
              labelStyle: const TextStyle(color: BearWaveTheme.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: Translations.get(context, 'streamUrl'),
              labelStyle: const TextStyle(color: BearWaveTheme.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _countryController,
            decoration: InputDecoration(
              labelText: Translations.get(context, 'countryOptional'),
              labelStyle: const TextStyle(color: BearWaveTheme.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            Translations.get(context, 'cancel'),
            style: const TextStyle(color: BearWaveTheme.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _urlController.text.isNotEmpty) {
              widget.onAdd(
                _nameController.text,
                _urlController.text,
                _countryController.text,
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(Translations.get(context, 'add')),
        ),
      ],
    );
  }
}