// lib/core/utils/extensions.dart
// Handy extension methods used throughout the app

extension DurationFormatting on Duration {
  /// Format as HH:MM:SS — used for the active sharing timer
  String toHms() {
    final h = inHours.toString().padLeft(2, '0');
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (inHours > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}

extension TimeOfDaySpeak on DateTime {
  /// Format time as spoken TTS string e.g. "5:30 PM"
  String toSpokenTime() {
    final hour = this.hour % 12 == 0 ? 12 : this.hour % 12;
    final minute = this.minute.toString().padLeft(2, '0');
    final period = this.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Format for display
  String toDisplayTime() => toSpokenTime();
}

extension ListSafety<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
