// lib/domain/repositories/settings_repository.dart
// Abstract interface for settings persistence

import '../entities/audio_settings.dart';
import '../entities/app_settings.dart';

/// Contract for settings operations — implemented via SharedPreferences
abstract class SettingsRepository {
  Future<AudioSettings> getAudioSettings();
  Future<void> saveAudioSettings(AudioSettings settings);

  Future<AppSettings> getAppSettings();
  Future<void> saveAppSettings(AppSettings settings);
}
