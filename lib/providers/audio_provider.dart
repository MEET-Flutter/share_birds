// lib/providers/audio_provider.dart
// Riverpod notifier for audio sharing state and controls

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/audio_settings.dart';
import '../domain/entities/sharing_state.dart';
import '../domain/repositories/audio_repository.dart';
import '../domain/repositories/bluetooth_repository.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';

// ── Audio Sharing Notifier ───────────────────────────────────────────────────

class AudioSharingNotifier extends Notifier<SharingState> {
  AudioRepository get _audioRepo => ref.read(audioRepositoryProvider);
  BluetoothRepository get _btRepo => ref.read(bluetoothRepositoryProvider);

  Timer? _durationTimer;
  StreamSubscription<double>? _levelSub;

  @override
  SharingState build() {
    // Clean up when provider is disposed
    ref.onDispose(() {
      _durationTimer?.cancel();
      _levelSub?.cancel();
    });
    return SharingState.initial;
  }

  /// Start audio sharing — enables BT SCO, starts native service
  Future<void> startSharing() async {
    if (state.isLive || state.isConnecting) return;

    state = state.copyWith(status: SharingStatus.connecting, errorMessage: null);

    try {
      // Get audio settings for this session
      final audioSettings = ref.read(audioSettingsProvider).valueOrNull
          ?? const AudioSettings();

      // Enable Bluetooth SCO for low-latency headset audio routing
      if (audioSettings.useBluetoothMic) {
        await _btRepo.enableBluetoothSco();
        await Future.delayed(const Duration(milliseconds: 600));
      } else {
        await _btRepo.disableBluetoothSco();
      }

      // Start native AudioRecord → AudioTrack foreground service
      await _audioRepo.startSharing(audioSettings);

      state = state.copyWith(
        status: SharingStatus.live,
        activeDuration: Duration.zero,
      );

      // Start elapsed timer
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        state = state.copyWith(
          activeDuration: state.activeDuration + const Duration(seconds: 1),
        );
      });

      // Subscribe to audio level updates
      _levelSub?.cancel();
      _levelSub = _audioRepo.audioLevelStream.listen(
        (level) {
          if (state.isLive) {
            state = state.copyWith(audioLevel: level);
          }
        },
        onError: (_) {},
      );
    } catch (e) {
      state = state.copyWith(
        status: SharingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Stop audio sharing — stops service and disables BT SCO
  Future<void> stopSharing() async {
    _durationTimer?.cancel();
    _levelSub?.cancel();

    try {
      await _audioRepo.stopSharing();
      await _btRepo.disableBluetoothSco();
    } catch (_) {
      // Best-effort cleanup
    }

    state = SharingState.initial;
  }

  /// Apply updated settings to running engine
  Future<void> applySettings(AudioSettings settings) async {
    if (state.isLive) {
      await _audioRepo.applySettings(settings);
    }
  }
}

final audioSharingProvider = NotifierProvider<AudioSharingNotifier, SharingState>(
  AudioSharingNotifier.new,
);

/// Stream provider for audio level bars
final audioLevelProvider = StreamProvider<double>((ref) {
  final repo = ref.watch(audioRepositoryProvider);
  return repo.audioLevelStream;
});
