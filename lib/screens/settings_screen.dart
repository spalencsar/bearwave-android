import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stations_provider.dart';
import '../theme/bearwave_theme.dart';
import '../l10n/translations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stations = context.read<StationsProvider>();
      if (stations.countries.isEmpty) {
        stations.loadCountries();
      }
    });
  }

  void _showCountryPicker(BuildContext context, StationsProvider stations, SettingsProvider settings) {
    if (stations.countries.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: BearWaveTheme.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BearWaveTheme.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Translations.get(context, 'defaultCountry'),
                style: const TextStyle(
                  color: BearWaveTheme.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: stations.countries.length,
                  itemBuilder: (ctx, i) {
                    final country = stations.countries[i];
                    final isSelected = settings.defaultCountry == country.code;
                    return ListTile(
                      leading: Text(
                        BearWaveTheme.getFlagEmoji(country.code),
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        country.name,
                        style: TextStyle(
                          color: isSelected ? BearWaveTheme.accent : BearWaveTheme.textMain,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: BearWaveTheme.accent)
                          : null,
                      onTap: () {
                        settings.setDefaultCountry(country.code);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: BearWaveTheme.accent.withValues(alpha: 0.9),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionBox({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: BearWaveTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BearWaveTheme.cardBorder),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: BearWaveTheme.cardBorder.withValues(alpha: 0.5),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: BearWaveTheme.accent),
      title: Text(
        title,
        style: const TextStyle(
          color: BearWaveTheme.textMain,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: BearWaveTheme.textMuted),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final stations = context.watch<StationsProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: BearWaveTheme.spaceGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            Translations.get(context, 'settings'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Allgemein
            _buildSectionTitle(Translations.get(context, 'general')),
            _buildSectionBox(
              children: [
                _buildListTile(
                  icon: Icons.language,
                  title: Translations.get(context, 'language'),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.language,
                      dropdownColor: BearWaveTheme.panel,
                      style: const TextStyle(color: BearWaveTheme.textMain, fontSize: 16),
                      icon: const Icon(Icons.arrow_drop_down, color: BearWaveTheme.textMuted),
                      items: const [
                        DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'nl', child: Text('Nederlands')),
                      ],
                      onChanged: (val) {
                        if (val != null) settings.setLanguage(val);
                      },
                    ),
                  ),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.public,
                  title: Translations.get(context, 'defaultCountry'),
                  trailing: stations.countries.isEmpty
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: BearWaveTheme.accent),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              BearWaveTheme.getFlagEmoji(settings.defaultCountry),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              settings.defaultCountry,
                              style: const TextStyle(color: BearWaveTheme.textMain, fontSize: 16),
                            ),
                            const Icon(Icons.chevron_right, color: BearWaveTheme.textMuted),
                          ],
                        ),
                  onTap: () => _showCountryPicker(context, stations, settings),
                ),
              ],
            ),

            // Wiedergabe
            _buildSectionTitle(Translations.get(context, 'playback')),
            _buildSectionBox(
              children: [
                _buildListTile(
                  icon: Icons.play_circle_outline,
                  title: Translations.get(context, 'autoplayOnStartup'),
                  trailing: Switch(
                    value: settings.autoplayOnStartup,
                    activeTrackColor: BearWaveTheme.accent.withAlpha(128),
                    activeThumbColor: BearWaveTheme.accent,
                    onChanged: settings.setAutoplayOnStartup,
                  ),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.bluetooth_audio,
                  title: Translations.get(context, 'resumeAfterBluetooth'),
                  trailing: Switch(
                    value: settings.resumeAfterBluetoothDisconnect,
                    activeTrackColor: BearWaveTheme.accent.withAlpha(128),
                    activeThumbColor: BearWaveTheme.accent,
                    onChanged: settings.setResumeAfterBluetoothDisconnect,
                  ),
                ),
                _buildDivider(),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed, color: BearWaveTheme.accent),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              Translations.get(context, 'playbackBuffer'),
                              style: const TextStyle(
                                color: BearWaveTheme.textMain,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text('${settings.playbackBuffer} s', style: const TextStyle(color: BearWaveTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: settings.playbackBuffer.toDouble(),
                        min: 10,
                        max: 120,
                        divisions: 110,
                        activeColor: BearWaveTheme.accent,
                        onChanged: (val) => settings.setPlaybackBuffer(val.toInt()),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Daten & Netzwerk
            _buildSectionTitle(Translations.get(context, 'dataAndNetwork')),
            _buildSectionBox(
              children: [
                _buildListTile(
                  icon: Icons.image,
                  title: Translations.get(context, 'showMetadataCover'),
                  trailing: Switch(
                    value: settings.showMetadataCover,
                    activeTrackColor: BearWaveTheme.accent.withAlpha(128),
                    activeThumbColor: BearWaveTheme.accent,
                    onChanged: settings.setShowMetadataCover,
                  ),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.hd,
                  title: Translations.get(context, 'coverQuality'),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.coverQuality,
                      dropdownColor: BearWaveTheme.panel,
                      style: const TextStyle(color: BearWaveTheme.textMain, fontSize: 16),
                      icon: const Icon(Icons.arrow_drop_down, color: BearWaveTheme.textMuted),
                      items: [
                        DropdownMenuItem(value: 'low', child: Text(Translations.get(context, 'coverQualityLow'))),
                        DropdownMenuItem(value: 'medium', child: Text(Translations.get(context, 'coverQualityMedium'))),
                        DropdownMenuItem(value: 'high', child: Text(Translations.get(context, 'coverQualityHigh'))),
                      ],
                      onChanged: (val) {
                        if (val != null) settings.setCoverQuality(val);
                      },
                    ),
                  ),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.cell_wifi,
                  title: Translations.get(context, 'alwaysTryConnect'),
                  trailing: Switch(
                    value: settings.alwaysTryToConnect,
                    activeTrackColor: BearWaveTheme.accent.withAlpha(128),
                    activeThumbColor: BearWaveTheme.accent,
                    onChanged: settings.setAlwaysTryToConnect,
                  ),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: Icons.data_saver_on,
                  title: Translations.get(context, 'preferLowBitrate'),
                  trailing: Switch(
                    value: settings.preferLowBitrate,
                    activeTrackColor: BearWaveTheme.accent.withAlpha(128),
                    activeThumbColor: BearWaveTheme.accent,
                    onChanged: settings.setPreferLowBitrate,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
