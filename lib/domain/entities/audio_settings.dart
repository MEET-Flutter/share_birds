// lib/domain/entities/audio_settings.dart
// Audio quality settings entity

/// Immutable entity representing audio processing settings
class AudioSettings {
  final bool lowLatencyMode;
  final bool gainBoost;
  final bool noiseSuppression;
  final bool echoCancellation;
  final bool useBluetoothMic;

  // New Equalizer & DSP fields
  final String eqPreset; // 'flat', 'super_hearing', 'vocal_boost', 'de_noise', 'bass_boost', 'custom'
  final List<double> eqBands; // 7 bands: 60Hz, 150Hz, 400Hz, 1kHz, 2.4kHz, 6kHz, 12kHz (-12dB to +12dB)
  final double leftBalance; // 0.0 to 1.0
  final double rightBalance; // 0.0 to 1.0
  final double voxThreshold; // 0.0 to 1.0 (0.0 = off)
  final int sleepTimerMinutes; // 0 = off

  // Multi-Earbud & Speaker Pass-Through fields
  final bool playToPhoneSpeaker; // Also play through phone's loudspeaker
  final bool dualEarbudMode; // Broadcast to multiple connected Bluetooth earbuds
  final String? recordingPath; // Path for saving live mic PCM audio

  const AudioSettings({
    this.lowLatencyMode   = true,
    this.gainBoost        = false,
    this.noiseSuppression = false,
    this.echoCancellation = false,
    this.useBluetoothMic  = true,
    this.eqPreset         = 'flat',
    this.eqBands          = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    this.leftBalance      = 1.0,
    this.rightBalance     = 1.0,
    this.voxThreshold     = 0.0,
    this.sleepTimerMinutes = 0,
    this.playToPhoneSpeaker = false,
    this.dualEarbudMode   = false,
    this.recordingPath,
  });

  AudioSettings copyWith({
    bool? lowLatencyMode,
    bool? gainBoost,
    bool? noiseSuppression,
    bool? echoCancellation,
    bool? useBluetoothMic,
    String? eqPreset,
    List<double>? eqBands,
    double? leftBalance,
    double? rightBalance,
    double? voxThreshold,
    int? sleepTimerMinutes,
    bool? playToPhoneSpeaker,
    bool? dualEarbudMode,
    String? recordingPath,
  }) {
    return AudioSettings(
      lowLatencyMode:    lowLatencyMode   ?? this.lowLatencyMode,
      gainBoost:         gainBoost        ?? this.gainBoost,
      noiseSuppression:  noiseSuppression ?? this.noiseSuppression,
      echoCancellation:  echoCancellation ?? this.echoCancellation,
      useBluetoothMic:   useBluetoothMic  ?? this.useBluetoothMic,
      eqPreset:          eqPreset         ?? this.eqPreset,
      eqBands:           eqBands          ?? this.eqBands,
      leftBalance:       leftBalance      ?? this.leftBalance,
      rightBalance:      rightBalance     ?? this.rightBalance,
      voxThreshold:      voxThreshold     ?? this.voxThreshold,
      sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
      playToPhoneSpeaker: playToPhoneSpeaker ?? this.playToPhoneSpeaker,
      dualEarbudMode:    dualEarbudMode   ?? this.dualEarbudMode,
      recordingPath:     recordingPath    ?? this.recordingPath,
    );
  }

  /// Convert to map for passing via platform channel
  Map<String, dynamic> toMap() => {
    'lowLatencyMode':    lowLatencyMode,
    'gainBoost':         gainBoost,
    'noiseSuppression':  noiseSuppression,
    'echoCancellation':  echoCancellation,
    'useBluetoothMic':   useBluetoothMic,
    'eqPreset':          eqPreset,
    'eqBands':           eqBands,
    'leftBalance':       leftBalance,
    'rightBalance':      rightBalance,
    'voxThreshold':      voxThreshold,
    'sleepTimerMinutes': sleepTimerMinutes,
    'playToPhoneSpeaker': playToPhoneSpeaker,
    'dualEarbudMode':    dualEarbudMode,
    'recordingPath':     recordingPath,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioSettings &&
          lowLatencyMode     == other.lowLatencyMode &&
          gainBoost          == other.gainBoost &&
          noiseSuppression   == other.noiseSuppression &&
          echoCancellation   == other.echoCancellation &&
          useBluetoothMic    == other.useBluetoothMic &&
          eqPreset           == other.eqPreset &&
          leftBalance        == other.leftBalance &&
          rightBalance       == other.rightBalance &&
          voxThreshold       == other.voxThreshold &&
          sleepTimerMinutes  == other.sleepTimerMinutes &&
          playToPhoneSpeaker == other.playToPhoneSpeaker &&
          dualEarbudMode    == other.dualEarbudMode;

  @override
  int get hashCode => Object.hash(
        lowLatencyMode, gainBoost, noiseSuppression, echoCancellation, useBluetoothMic,
        eqPreset, leftBalance, rightBalance, voxThreshold, sleepTimerMinutes,
        playToPhoneSpeaker, dualEarbudMode,
      );
}

