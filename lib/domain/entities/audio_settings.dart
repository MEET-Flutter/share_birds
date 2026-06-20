// lib/domain/entities/audio_settings.dart
// Audio quality settings entity

/// Immutable entity representing audio processing settings
class AudioSettings {
  final bool lowLatencyMode;
  final bool gainBoost;
  final bool noiseSuppression;
  final bool echoCancellation;
  final bool useBluetoothMic;

  const AudioSettings({
    this.lowLatencyMode   = true,
    this.gainBoost        = false,
    this.noiseSuppression = false,
    this.echoCancellation = false,
    this.useBluetoothMic  = true,
  });

  AudioSettings copyWith({
    bool? lowLatencyMode,
    bool? gainBoost,
    bool? noiseSuppression,
    bool? echoCancellation,
    bool? useBluetoothMic,
  }) {
    return AudioSettings(
      lowLatencyMode:   lowLatencyMode   ?? this.lowLatencyMode,
      gainBoost:        gainBoost        ?? this.gainBoost,
      noiseSuppression: noiseSuppression ?? this.noiseSuppression,
      echoCancellation: echoCancellation ?? this.echoCancellation,
      useBluetoothMic:  useBluetoothMic  ?? this.useBluetoothMic,
    );
  }

  /// Convert to map for passing via platform channel
  Map<String, dynamic> toMap() => {
    'lowLatencyMode':   lowLatencyMode,
    'gainBoost':        gainBoost,
    'noiseSuppression': noiseSuppression,
    'echoCancellation': echoCancellation,
    'useBluetoothMic':  useBluetoothMic,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioSettings &&
          lowLatencyMode   == other.lowLatencyMode &&
          gainBoost        == other.gainBoost &&
          noiseSuppression == other.noiseSuppression &&
          echoCancellation == other.echoCancellation &&
          useBluetoothMic  == other.useBluetoothMic;

  @override
  int get hashCode => Object.hash(lowLatencyMode, gainBoost, noiseSuppression, echoCancellation, useBluetoothMic);
}
