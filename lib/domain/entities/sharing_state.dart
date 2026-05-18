// lib/domain/entities/sharing_state.dart
// Sharing state domain entity

/// Enum representing the current audio sharing state
enum SharingStatus {
  stopped,
  connecting,
  live,
  error,
}

/// Full state of the audio sharing session
class SharingState {
  final SharingStatus status;
  final Duration activeDuration;
  final double audioLevel;        // 0.0 – 1.0
  final String? errorMessage;

  const SharingState({
    this.status        = SharingStatus.stopped,
    this.activeDuration = Duration.zero,
    this.audioLevel    = 0.0,
    this.errorMessage,
  });

  bool get isLive       => status == SharingStatus.live;
  bool get isConnecting => status == SharingStatus.connecting;
  bool get isStopped    => status == SharingStatus.stopped;
  bool get hasError     => status == SharingStatus.error;

  SharingState copyWith({
    SharingStatus? status,
    Duration? activeDuration,
    double? audioLevel,
    String? errorMessage,
  }) {
    return SharingState(
      status:         status         ?? this.status,
      activeDuration: activeDuration ?? this.activeDuration,
      audioLevel:     audioLevel     ?? this.audioLevel,
      errorMessage:   errorMessage   ?? this.errorMessage,
    );
  }

  static const SharingState initial = SharingState();
}
