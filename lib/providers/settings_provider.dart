// lib/providers/settings_provider.dart
// Riverpod notifiers for audio and app settings

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/audio_settings.dart';
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';
import 'repository_providers.dart';

// ── Audio Settings Notifier ──────────────────────────────────────────────────

class AudioSettingsNotifier extends AsyncNotifier<AudioSettings> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<AudioSettings> build() async {
    return _repo.getAudioSettings();
  }

  Future<void> toggleLowLatency(bool v) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(lowLatencyMode: v);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> toggleGainBoost(bool v) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(gainBoost: v);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> toggleNoiseSuppression(bool v) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(noiseSuppression: v);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> toggleEchoCancellation(bool v) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(echoCancellation: v);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> toggleUseBluetoothMic(bool v) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(useBluetoothMic: v);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> setEqPreset(String preset, List<double> bands) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(eqPreset: preset, eqBands: bands);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> setEqBand(int index, double value) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final newBands = List<double>.from(current.eqBands);
    if (index >= 0 && index < newBands.length) {
      newBands[index] = value;
    }
    final updated = current.copyWith(eqPreset: 'custom', eqBands: newBands);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> setBalance(double left, double right) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(leftBalance: left, rightBalance: right);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> setVoxThreshold(double threshold) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(voxThreshold: threshold);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> setSleepTimer(int minutes) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(sleepTimerMinutes: minutes);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> togglePlayToPhoneSpeaker(bool v) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(playToPhoneSpeaker: v);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }

  Future<void> toggleDualEarbudMode(bool v) async {
    final current = state.valueOrNull ?? const AudioSettings();
    final updated = current.copyWith(dualEarbudMode: v);
    state = AsyncData(updated);
    await _repo.saveAudioSettings(updated);
  }
}

final audioSettingsProvider = AsyncNotifierProvider<AudioSettingsNotifier, AudioSettings>(
  AudioSettingsNotifier.new,
);

// ── App Settings Notifier ────────────────────────────────────────────────────

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<AppSettings> build() async {
    return _repo.getAppSettings();
  }

  Future<void> toggleAnnounceTime(bool v) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(announceTime: v);
    state = AsyncData(updated);
    await _repo.saveAppSettings(updated);
  }

  Future<void> setAnnounceInterval(int minutes) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(announceIntervalMinutes: minutes);
    state = AsyncData(updated);
    await _repo.saveAppSettings(updated);
  }

  Future<void> toggleDarkMode(bool v) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(isDarkMode: v);
    state = AsyncData(updated);
    await _repo.saveAppSettings(updated);
  }
}

final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
