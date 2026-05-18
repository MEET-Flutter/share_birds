// lib/domain/repositories/audio_repository.dart
// Abstract interface for audio operations

import '../entities/audio_settings.dart';

/// Contract for audio operations — implemented in the data layer
abstract class AudioRepository {
  /// Start audio capture → playback loop (via native foreground service)
  Future<void> startSharing(AudioSettings settings);

  /// Stop audio loop and foreground service
  Future<void> stopSharing();

  /// Returns true if the native engine is currently running
  Future<bool> isSharing();

  /// Stream of audio level values (0.0 – 1.0) for waveform animation
  Stream<double> get audioLevelStream;

  /// Apply new settings to the running engine without restart
  Future<void> applySettings(AudioSettings settings);
}
