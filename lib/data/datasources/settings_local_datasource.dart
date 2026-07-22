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
    final eqBandsRaw = _prefs.getStringList(PrefKeys.eqBands);
    final eqBands = eqBandsRaw != null
        ? eqBandsRaw.map((e) => double.tryParse(e) ?? 0.0).toList()
        : const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    return AudioSettings(
      lowLatencyMode:   _prefs.getBool(PrefKeys.lowLatencyMode)   ?? true,
      gainBoost:        _prefs.getBool(PrefKeys.gainBoost)        ?? false,
      noiseSuppression: _prefs.getBool(PrefKeys.noiseSuppression) ?? false,
      echoCancellation: _prefs.getBool(PrefKeys.echoCancellation) ?? false,
      useBluetoothMic:  _prefs.getBool(PrefKeys.useBluetoothMic)  ?? true,
      eqPreset:         _prefs.getString(PrefKeys.eqPreset)      ?? 'flat',
      eqBands:          eqBands,
      leftBalance:      _prefs.getDouble(PrefKeys.leftBalance)    ?? 1.0,
      rightBalance:     _prefs.getDouble(PrefKeys.rightBalance)   ?? 1.0,
      voxThreshold:     _prefs.getDouble(PrefKeys.voxThreshold)   ?? 0.0,
      playToPhoneSpeaker: _prefs.getBool(PrefKeys.playToPhoneSpeaker) ?? false,
      dualEarbudMode:    _prefs.getBool(PrefKeys.dualEarbudMode)   ?? false,
    );
  }

  Future<void> saveAudioSettings(AudioSettings s) async {
    await Future.wait([
      _prefs.setBool(PrefKeys.lowLatencyMode,   s.lowLatencyMode),
      _prefs.setBool(PrefKeys.gainBoost,        s.gainBoost),
      _prefs.setBool(PrefKeys.noiseSuppression, s.noiseSuppression),
      _prefs.setBool(PrefKeys.echoCancellation, s.echoCancellation),
      _prefs.setBool(PrefKeys.useBluetoothMic,  s.useBluetoothMic),
      _prefs.setString(PrefKeys.eqPreset,       s.eqPreset),
      _prefs.setStringList(PrefKeys.eqBands,    s.eqBands.map((e) => e.toString()).toList()),
      _prefs.setDouble(PrefKeys.leftBalance,    s.leftBalance),
      _prefs.setDouble(PrefKeys.rightBalance,   s.rightBalance),
      _prefs.setDouble(PrefKeys.voxThreshold,   s.voxThreshold),
      _prefs.setBool(PrefKeys.playToPhoneSpeaker, s.playToPhoneSpeaker),
      _prefs.setBool(PrefKeys.dualEarbudMode,   s.dualEarbudMode),
    ]);
  }

  // ── App Settings ────────────────────────────────────────────────────────────

  AppSettings getAppSettings() {
    return AppSettings(
      announceTime:            _prefs.getBool(PrefKeys.announceTime)      ?? false,
      announceIntervalMinutes: _prefs.getInt(PrefKeys.announceInterval)   ?? 30,
      isDarkMode:              _prefs.getBool(PrefKeys.isDarkMode)        ?? true,
    );
  }

  Future<void> saveAppSettings(AppSettings s) async {
    await Future.wait([
      _prefs.setBool(PrefKeys.announceTime,    s.announceTime),
      _prefs.setInt(PrefKeys.announceInterval, s.announceIntervalMinutes),
      _prefs.setBool(PrefKeys.isDarkMode,       s.isDarkMode),
    ]);
  }
}
