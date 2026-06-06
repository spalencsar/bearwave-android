import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cast_service.dart';
import '../theme/bearwave_theme.dart';

class CastDialog extends StatefulWidget {
  const CastDialog({super.key});

  @override
  State<CastDialog> createState() => _CastDialogState();
}

class _CastDialogState extends State<CastDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CastService>().searchDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BearWaveTheme.panel.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Consumer<CastService>(
              builder: (context, castService, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.cast,
                          color: BearWaveTheme.accent,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Wiedergabegerät wählen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (castService.isSearching)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: BearWaveTheme.accent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (castService.devices.isEmpty && !castService.isSearching)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.wifi_tethering_off,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sucht nach Lautsprechern und TVs im WLAN...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        itemCount: castService.devices.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        itemBuilder: (context, index) {
                          final device = castService.devices[index];
                          final isConnected =
                              castService.connectedDevice?.host == device.host;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isConnected
                                      ? BearWaveTheme.accent.withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isConnected
                                      ? Icons.cast_connected
                                      : Icons.speaker,
                                  color: isConnected
                                      ? BearWaveTheme.accent
                                      : Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              title: Text(
                                device.name,
                                style: TextStyle(
                                  color: isConnected
                                      ? BearWaveTheme.accent
                                      : Colors.white,
                                  fontWeight: isConnected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                device.host,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isConnected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: BearWaveTheme.accent,
                                    )
                                  : null,
                              onTap: () {
                                if (!isConnected) {
                                  castService.connectToDevice(device);
                                }
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),

                    if (castService.isConnected) ...[
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withValues(alpha: 0.1)),
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BearWaveTheme.warn.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: BearWaveTheme.warn,
                            ),
                          ),
                          title: const Text(
                            'Verbindung trennen',
                            style: TextStyle(
                              color: BearWaveTheme.warn,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            castService.disconnect();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
