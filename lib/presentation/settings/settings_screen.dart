// lib/presentation/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioSettings = ref.watch(audioSettingsProvider).valueOrNull;
    final appSettings   = ref.watch(appSettingsProvider).valueOrNull;
    final audioNotifier = ref.read(audioSettingsProvider.notifier);
    final appNotifier   = ref.read(appSettingsProvider.notifier);

    final scaffoldBg  = AppColors.getScaffoldBg(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSec     = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textSec),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: TextStyle(color: textPrimary)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Audio Quality ────────────────────────────────────────────────────
          const _SectionHeader(icon: Icons.tune_rounded, title: 'Audio Quality'),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            _ToggleTile(
              icon:    Icons.flash_on_rounded,
              title:   'Low Latency Mode',
              subtitle: 'Minimize buffer size for fastest audio',
              color:   AppColors.primary,
              value:   audioSettings?.lowLatencyMode ?? true,
              onChanged: audioSettings != null
                  ? (v) => audioNotifier.toggleLowLatency(v)
                  : null,
            ),
            _Divider(),
            _ToggleTile(
              icon:    Icons.volume_up_rounded,
              title:   'Gain Boost',
              subtitle: 'Amplify microphone input signal',
              color:   AppColors.secondary,
              value:   audioSettings?.gainBoost ?? false,
              onChanged: audioSettings != null
                  ? (v) => audioNotifier.toggleGainBoost(v)
                  : null,
            ),
            _Divider(),
            _ToggleTile(
              icon:    Icons.noise_control_off_rounded,
              title:   'Noise Suppression',
              subtitle: 'Reduce background noise',
              color:   AppColors.liveGreen,
              value:   audioSettings?.noiseSuppression ?? false,
              onChanged: audioSettings != null
                  ? (v) => audioNotifier.toggleNoiseSuppression(v)
                  : null,
            ),
            _Divider(),
            _ToggleTile(
              icon:    Icons.spatial_audio_off_rounded,
              title:   'Echo Cancellation',
              subtitle: 'Prevent audio feedback loop',
              color:   AppColors.warningAmber,
              value:   audioSettings?.echoCancellation ?? false,
              onChanged: audioSettings != null
                  ? (v) => audioNotifier.toggleEchoCancellation(v)
                  : null,
            ),
            _Divider(),
            _ToggleTile(
              icon:    Icons.bluetooth_audio_rounded,
              title:   'Use Bluetooth Microphone',
              subtitle: 'Use headset mic; disable to use phone mic with high-quality playback',
              color:   AppColors.primary,
              value:   audioSettings?.useBluetoothMic ?? true,
              onChanged: audioSettings != null
                  ? (v) => audioNotifier.toggleUseBluetoothMic(v)
                  : null,
            ),
            _Divider(),
            _ToggleTile(
              icon:    Icons.volume_up_outlined,
              title:   'Phone Speaker Pass-Through',
              subtitle: 'Play earbud mic sound out of phone loudspeaker alongside earbuds',
              color:   AppColors.secondary,
              value:   audioSettings?.playToPhoneSpeaker ?? false,
              onChanged: audioSettings != null
                  ? (v) => audioNotifier.togglePlayToPhoneSpeaker(v)
                  : null,
            ),
            _Divider(),
            _ToggleTile(
              icon:    Icons.people_outline_rounded,
              title:   'Multi-Earbud Intercom Relay',
              subtitle: 'Broadcast mic audio to multiple connected Bluetooth earbuds so users hear each other',
              color:   AppColors.liveGreen,
              value:   audioSettings?.dualEarbudMode ?? false,
              onChanged: audioSettings != null
                  ? (v) => audioNotifier.toggleDualEarbudMode(v)
                  : null,
            ),
          ]),
          const SizedBox(height: 28),

          // ── Appearance & Theme ──────────────────────────────────────────────
          const _SectionHeader(icon: Icons.palette_outlined, title: 'Appearance & Theme'),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            _ToggleTile(
              icon:    (appSettings?.isDarkMode ?? true) ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title:   'Dark Mode Theme',
              subtitle: (appSettings?.isDarkMode ?? true) ? 'Electric Space Dark theme active' : 'Clean Arctic Light theme active',
              color:   AppColors.primary,
              value:   appSettings?.isDarkMode ?? true,
              onChanged: appSettings != null
                  ? (v) => appNotifier.toggleDarkMode(v)
                  : null,
            ),
          ]),
          const SizedBox(height: 28),

          // ── Time Announcements ───────────────────────────────────────────────
          const _SectionHeader(icon: Icons.access_time_rounded, title: 'Time Announcements'),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            _ToggleTile(
              icon:    Icons.record_voice_over_rounded,
              title:   'Announce Current Time',
              subtitle: 'Speak time periodically via TTS',
              color:   AppColors.secondary,
              value:   appSettings?.announceTime ?? false,
              onChanged: appSettings != null
                  ? (v) => appNotifier.toggleAnnounceTime(v)
                  : null,
            ),
            if (appSettings?.announceTime == true) ...[
              _Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Announcement Interval',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 14,
                          fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: TimeIntervals.options.map((min) {
                        final selected = appSettings?.announceIntervalMinutes == min;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => appNotifier.setAnnounceInterval(min),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.secondary.withValues(alpha: 0.2)
                                    : AppColors.surfaceMid,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? AppColors.secondary : AppColors.border,
                                ),
                              ),
                              child: Text(
                                TimeIntervals.label(min),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? AppColors.secondary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ]),
          const SizedBox(height: 28),

          // ── About ────────────────────────────────────────────────────────────
          const _SectionHeader(icon: Icons.info_outline_rounded, title: 'About'),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.headphones_rounded, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('SpyEar',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 16,
                              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('Version 1.0.0',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                              color: AppColors.textSecondary)),
                    ]),
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    'Stream live microphone audio to your Bluetooth earbuds. '
                    'Place your phone anywhere and listen remotely.',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 13,
                        color: AppColors.textSecondary, height: 1.6),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final textSec = AppColors.getTextSecondary(context);
    return Row(children: [
      Icon(icon, color: textSec, size: 16),
      const SizedBox(width: 8),
      Text(title.toUpperCase(),
          style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
              fontWeight: FontWeight.w700, color: textSec,
              letterSpacing: 1.5)),
    ]);
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurfaceBg(context);
    final border  = AppColors.getBorder(context);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleTile({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.value, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSec     = AppColors.getTextSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: 'Outfit', fontSize: 15,
              fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
              color: textSec)),
        ])),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final border = AppColors.getBorder(context);
    return Divider(color: border, height: 1, indent: 16, endIndent: 16);
  }
}
