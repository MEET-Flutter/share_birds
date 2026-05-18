// lib/data/repositories/settings_repository_impl.dart
// Concrete implementation of SettingsRepository

import '../../domain/entities/audio_settings.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource _datasource;

  SettingsRepositoryImpl(this._datasource);

  @override
  Future<AudioSettings> getAudioSettings() async {
    return _datasource.getAudioSettings();
  }

  @override
  Future<void> saveAudioSettings(AudioSettings settings) async {
    await _datasource.saveAudioSettings(settings);
  }

  @override
  Future<AppSettings> getAppSettings() async {
    return _datasource.getAppSettings();
  }

  @override
  Future<void> saveAppSettings(AppSettings settings) async {
    await _datasource.saveAppSettings(settings);
  }
}
