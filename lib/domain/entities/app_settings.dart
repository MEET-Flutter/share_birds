// lib/domain/entities/app_settings.dart
// App-level settings (TTS, announcement interval, etc.)

/// Global app settings entity
class AppSettings {
  final bool announceTime;
  final int  announceIntervalMinutes;
  final bool isDarkMode; // Dark / Light Mode theme toggle

  const AppSettings({
    this.announceTime             = false,
    this.announceIntervalMinutes  = 30,
    this.isDarkMode               = true,
  });

  AppSettings copyWith({
    bool? announceTime,
    int?  announceIntervalMinutes,
    bool? isDarkMode,
  }) {
    return AppSettings(
      announceTime:            announceTime            ?? this.announceTime,
      announceIntervalMinutes: announceIntervalMinutes ?? this.announceIntervalMinutes,
      isDarkMode:              isDarkMode              ?? this.isDarkMode,
    );
  }
}
