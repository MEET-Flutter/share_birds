// lib/providers/repository_providers.dart
// Riverpod providers for all repositories and datasources (DI bindings)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/audio_platform_datasource.dart';
import '../data/datasources/bluetooth_platform_datasource.dart';
import '../data/datasources/settings_local_datasource.dart';
import '../data/repositories/audio_repository_impl.dart';
import '../data/repositories/bluetooth_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../domain/repositories/audio_repository.dart';
import '../domain/repositories/bluetooth_repository.dart';
import '../domain/repositories/settings_repository.dart';

// ── SharedPreferences ────────────────────────────────────────────────────────

/// Initialized at app startup via ProviderScope overrides
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// ── Datasources ──────────────────────────────────────────────────────────────

final audioDatasourceProvider = Provider<AudioPlatformDatasource>(
  (_) => AudioPlatformDatasource(),
);

final bluetoothDatasourceProvider = Provider<BluetoothPlatformDatasource>(
  (_) => BluetoothPlatformDatasource(),
);

final settingsDatasourceProvider = Provider<SettingsLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsLocalDatasource(prefs);
});

// ── Repositories ─────────────────────────────────────────────────────────────

final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  return AudioRepositoryImpl(ref.watch(audioDatasourceProvider));
});

final bluetoothRepositoryProvider = Provider<BluetoothRepository>((ref) {
  return BluetoothRepositoryImpl(ref.watch(bluetoothDatasourceProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(settingsDatasourceProvider));
});
