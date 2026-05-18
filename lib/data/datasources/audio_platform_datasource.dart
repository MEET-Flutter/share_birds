// lib/data/datasources/audio_platform_datasource.dart
// Bridges Dart ↔ Native Kotlin AudioSharingService via MethodChannel

import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

/// Platform channel data source for audio engine operations
class AudioPlatformDatasource {
  static const _channel = MethodChannel(ChannelNames.audio);
  static const _eventChannel = EventChannel(EventChannelNames.audioLevel);

  /// Start the native audio loopback engine
  Future<void> startSharing(Map<String, dynamic> settingsMap) async {
    try {
      await _channel.invokeMethod(AudioMethods.startSharing, settingsMap);
    } on PlatformException catch (e) {
      throw AudioFailure(e.message ?? 'Failed to start audio sharing');
    }
  }

  /// Stop the native engine and foreground service
  Future<void> stopSharing() async {
    try {
      await _channel.invokeMethod(AudioMethods.stopSharing);
    } on PlatformException catch (e) {
      throw AudioFailure(e.message ?? 'Failed to stop audio sharing');
    }
  }

  /// Returns current engine running state
  Future<bool> isSharing() async {
    try {
      final result = await _channel.invokeMethod<bool>(AudioMethods.isSharing);
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Returns raw audio amplitude 0..32767
  Future<double> getAudioLevel() async {
    try {
      final result = await _channel.invokeMethod<double>(AudioMethods.getAudioLevel);
      return result ?? 0.0;
    } on PlatformException {
      return 0.0;
    }
  }

  /// Apply settings to the running engine without restart
  Future<void> applySettings(Map<String, dynamic> settingsMap) async {
    try {
      await _channel.invokeMethod(AudioMethods.applySettings, settingsMap);
    } on PlatformException catch (e) {
      throw AudioFailure(e.message ?? 'Failed to apply settings');
    }
  }

  /// Stream of normalized audio levels (0.0 – 1.0) from EventChannel
  Stream<double> get audioLevelStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is double) return event.clamp(0.0, 1.0);
          if (event is num) return (event.toDouble() / 32767.0).clamp(0.0, 1.0);
          return 0.0;
        });
  }
}
