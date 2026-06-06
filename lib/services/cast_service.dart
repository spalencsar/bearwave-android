import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:cast_plus/cast.dart';

class CastService extends ChangeNotifier {
  CastDevice? _connectedDevice;
  CastSession? _session;
  final List<CastDevice> _devices = [];
  bool _isSearching = false;

  String? _castTransportId;
  int? _mediaSessionId;

  String? _pendingPlayUrl;
  String? _pendingPlayTitle;
  String? _pendingPlayArtwork;

  List<CastDevice> get devices => _devices;
  CastDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _session != null;
  bool get isSearching => _isSearching;

  Future<void> searchDevices() async {
    if (_isSearching) return;

    _isSearching = true;
    _devices.clear();
    notifyListeners();

    try {
      final discoveredDevices = await CastDiscoveryService().search();
      for (final device in discoveredDevices) {
        if (!_devices.any((d) => d.host == device.host)) {
          _devices.add(device);
        }
      }
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log(
        'Error searching for Cast devices',
        name: 'BearWave.CastService',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(CastDevice device) async {
    try {
      _session = await CastSessionManager().startSession(device);
      _session?.stateStream.listen((state) {
        if (state == CastSessionState.closed) {
          _connectedDevice = null;
          _session = null;
          notifyListeners();
        }
      });

      _session?.messageStream.listen((message) {
        developer.log(
          'Cast message received: $message',
          name: 'BearWave.CastService',
        );
        if (message['type'] == 'RECEIVER_STATUS') {
          final status = message['status'];
          if (status != null && status['applications'] != null) {
            final apps = status['applications'] as List;
            for (var app in apps) {
              if (app['appId'] == 'CC1AD845') {
                _castTransportId = app['transportId'];

                // Wir müssen auch CONNECT an die neue Transport-ID senden, da cast_plus das nicht macht!
                _session?.socket.sendMessage(
                  CastSession.kNamespaceConnection,
                  _session!.sessionId,
                  _castTransportId!,
                  {'type': 'CONNECT'},
                );

                if (_pendingPlayUrl != null) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    playStream(
                      _pendingPlayUrl!,
                      _pendingPlayTitle ?? '',
                      _pendingPlayArtwork ?? '',
                    );
                    _pendingPlayUrl = null;
                    _pendingPlayTitle = null;
                    _pendingPlayArtwork = null;
                  });
                }
              }
            }
          }
        } else if (message['type'] == 'MEDIA_STATUS') {
          final statusList = message['status'];
          if (statusList != null &&
              statusList is List &&
              statusList.isNotEmpty) {
            _mediaSessionId = statusList[0]['mediaSessionId'];
          }
        }
      });

      // Zuerst die Default Media Receiver App auf dem Chromecast starten
      _session?.sendMessage(CastSession.kNamespaceReceiver, {
        'type': 'LAUNCH',
        'appId': 'CC1AD845',
      });

      _connectedDevice = device;
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log(
        'Error connecting to Cast device',
        name: 'BearWave.CastService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> playStream(String url, String title, String artworkUrl) async {
    if (_session == null) return;

    if (_castTransportId == null) {
      _pendingPlayUrl = url;
      _pendingPlayTitle = title;
      _pendingPlayArtwork = artworkUrl;
      return;
    }

    // Chromecast requires HTTPS for streams, try to replace http if possible
    final secureUrl = url.replaceFirst('http://', 'https://');

    var media = {
      'contentId': secureUrl,
      'contentType': 'audio/mpeg',
      'streamType': 'BUFFERED',
      'metadata': {
        'type': 0,
        'metadataType': 0,
        'title': title,
        'images': [
          {'url': artworkUrl},
        ],
      },
    };

    _session?.socket.sendMessage(
      CastSession.kNamespaceMedia,
      _session!.sessionId,
      _castTransportId ?? 'receiver-0',
      {
        'type': 'LOAD',
        'autoplay': true,
        'currentTime': 0,
        'requestId': DateTime.now().millisecondsSinceEpoch,
        'media': media,
      },
    );
  }

  void stop() {
    if (_session == null ||
        _castTransportId == null ||
        _mediaSessionId == null) {
      return;
    }
    _session?.socket.sendMessage(
      CastSession.kNamespaceMedia,
      _session!.sessionId,
      _castTransportId!,
      {
        'type': 'STOP',
        'requestId': DateTime.now().millisecondsSinceEpoch,
        'mediaSessionId': _mediaSessionId,
      },
    );
  }

  void setVolume(double volume) {
    if (_session == null) return;
    _session?.socket.sendMessage(
      CastSession.kNamespaceReceiver,
      _session!.sessionId,
      'receiver-0',
      {
        'type': 'SET_VOLUME',
        'volume': {'level': volume},
        'requestId': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  void disconnect() {
    _session?.close();
    _session = null;
    _connectedDevice = null;
    _castTransportId = null;
    _mediaSessionId = null;
    _pendingPlayUrl = null;
    _pendingPlayTitle = null;
    _pendingPlayArtwork = null;
    notifyListeners();
  }
}
