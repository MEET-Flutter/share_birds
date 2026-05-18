// lib/data/datasources/settings_local_datasource.dart
// SharedPreferences-backed local storage for app settings

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/audio_settings.dart';
import '../../domain/entities/app_settings.dart';

/// Reads and writes settings to SharedPreferences
class SettingsLocalDatasource {
  final SharedPreferences _prefs;

  SettingsLocalDatasource(this._prefs);

  // ── Audio Settings ──────────────────────────────────────────────────────────

  AudioSettings getAudioSettings() {
    return AudioSettings(
      lowLatencyMode:   _prefs.getBool(PrefKeys.lowLatencyMode)   ?? true,
      gainBoost:        _prefs.getBool(PrefKeys.gainBoost)        ?? false,
      noiseSuppression: _prefs.getBool(PrefKeys.noiseSuppression) ?? false,
      echoCancellation: _prefs.getBool(PrefKeys.echoCancellation) ?? false,
    );
  }

  Future<void> saveAudioSettings(AudioSettings s) async {
    await Future.wait([
      _prefs.setBool(PrefKeys.lowLatencyMode,   s.lowLatencyMode),
      _prefs.setBool(PrefKeys.gainBoost,        s.gainBoost),
      _prefs.setBool(PrefKeys.noiseSuppression, s.noiseSuppression),
      _prefs.setBool(PrefKeys.echoCancellation, s.echoCancellation),
    ]);
  }

  // ── App Settings ────────────────────────────────────────────────────────────

  AppSettings getAppSettings() {
    return AppSettings(
      announceTime:            _prefs.getBool(PrefKeys.announceTime)      ?? false,
      announceIntervalMinutes: _prefs.getInt(PrefKeys.announceInterval)   ?? 30,
    );
  }

  Future<void> saveAppSettings(AppSettings s) async {
    await Future.wait([
      _prefs.setBool(PrefKeys.announceTime,    s.announceTime),
      _prefs.setInt(PrefKeys.announceInterval, s.announceIntervalMinutes),
    ]);
  }
}
