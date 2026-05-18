// lib/data/repositories/audio_repository_impl.dart
// Concrete implementation of AudioRepository

import '../../domain/entities/audio_settings.dart';
import '../../domain/repositories/audio_repository.dart';
import '../datasources/audio_platform_datasource.dart';

class AudioRepositoryImpl implements AudioRepository {
  final AudioPlatformDatasource _datasource;

  AudioRepositoryImpl(this._datasource);

  @override
  Future<void> startSharing(AudioSettings settings) async {
    await _datasource.startSharing(settings.toMap());
  }

  @override
  Future<void> stopSharing() async {
    await _datasource.stopSharing();
  }

  @override
  Future<bool> isSharing() async {
    return _datasource.isSharing();
  }

  @override
  Stream<double> get audioLevelStream => _datasource.audioLevelStream;

  @override
  Future<void> applySettings(AudioSettings settings) async {
    await _datasource.applySettings(settings.toMap());
  }
}
