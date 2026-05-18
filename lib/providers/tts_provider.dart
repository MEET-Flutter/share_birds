// lib/providers/tts_provider.dart
// TTS engine and time announcement scheduling

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/utils/extensions.dart';
import 'settings_provider.dart';

// ── TTS Engine Provider ──────────────────────────────────────────────────────

final ttsEngineProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage('en-US');
  tts.setSpeechRate(0.5);
  tts.setVolume(1.0);
  tts.setPitch(1.0);

  ref.onDispose(() => tts.stop());
  return tts;
});

// ── Time Announcement Notifier ───────────────────────────────────────────────

class TimeAnnouncementNotifier extends Notifier<void> {
  Timer? _timer;

  @override
  void build() {
    // Re-schedule when settings change
    ref.listen(appSettingsProvider, (_, next) {
      final settings = next.valueOrNull;
      if (settings != null) {
        _reschedule(settings.announceTime, settings.announceIntervalMinutes);
      }
    });

    ref.onDispose(() => _timer?.cancel());
  }

  void _reschedule(bool enabled, int intervalMinutes) {
    _timer?.cancel();
    if (!enabled) return;

    final interval = Duration(minutes: intervalMinutes);
    _timer = Timer.periodic(interval, (_) => _announce());
  }

  Future<void> _announce() async {
    final tts = ref.read(ttsEngineProvider);
    final now = DateTime.now();
    final spoken = now.toSpokenTime();
    await tts.speak('Current time is $spoken');
  }

  /// Manually trigger a time announcement (for testing)
  Future<void> announceNow() async {
    await _announce();
  }
}

final timeAnnouncementProvider = NotifierProvider<TimeAnnouncementNotifier, void>(
  TimeAnnouncementNotifier.new,
);
