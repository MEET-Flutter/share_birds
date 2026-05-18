// lib/domain/entities/app_settings.dart
// App-level settings (TTS, announcement interval, etc.)

/// Global app settings entity
class AppSettings {
  final bool announceTime;
  final int  announceIntervalMinutes;

  const AppSettings({
    this.announceTime             = false,
    this.announceIntervalMinutes  = 30,
  });

  AppSettings copyWith({
    bool? announceTime,
    int?  announceIntervalMinutes,
  }) {
    return AppSettings(
      announceTime:            announceTime            ?? this.announceTime,
      announceIntervalMinutes: announceIntervalMinutes ?? this.announceIntervalMinutes,
    );
  }
}
