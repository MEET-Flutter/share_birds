// lib/presentation/equalizer/equalizer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';

class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  static const List<Map<String, dynamic>> _presets = [
    {
      'id': 'flat',
      'label': 'Flat',
      'icon': Icons.horizontal_rule_rounded,
      'bands': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    },
    {
      'id': 'super_hearing',
      'label': 'Super Hearing',
      'icon': Icons.hearing_rounded,
      'bands': [2.0, 4.0, 6.0, 8.0, 10.0, 8.0, 6.0]
    },
    {
      'id': 'vocal_boost',
      'label': 'Vocal Boost',
      'icon': Icons.record_voice_over_rounded,
      'bands': [-2.0, 0.0, 4.0, 8.0, 6.0, 2.0, 0.0]
    },
    {
      'id': 'de_noise',
      'label': 'De-Noise',
      'icon': Icons.noise_control_off_rounded,
      'bands': [-6.0, -4.0, 0.0, 4.0, 6.0, 2.0, -4.0]
    },
    {
      'id': 'bass_boost',
      'label': 'Bass Boost',
      'icon': Icons.speaker_group_rounded,
      'bands': [8.0, 6.0, 4.0, 0.0, 0.0, 0.0, 0.0]
    },
  ];

  static const List<String> _bandFreqs = [
    '60Hz', '150Hz', '400Hz', '1kHz', '2.4kHz', '6kHz', '12kHz'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(audioSettingsProvider);
    final settings = settingsAsync.valueOrNull;
    final notifier = ref.read(audioSettingsProvider.notifier);

    final currentPreset = settings?.eqPreset ?? 'flat';
    final currentBands  = settings?.eqBands ?? const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final leftBal       = settings?.leftBalance ?? 1.0;
    final rightBal      = settings?.rightBalance ?? 1.0;
    final voxThresh     = settings?.voxThreshold ?? 0.0;

    final scaffoldBg    = AppColors.getScaffoldBg(context);
    final textPrimary   = AppColors.getTextPrimary(context);
    final primary       = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded, color: primary, size: 22),
            const SizedBox(width: 8),
            Text('Equalizer & Audio DSP', style: TextStyle(color: textPrimary)),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Presets ────────────────────────────────────────────────────────
          const _Header(title: 'SOUND PRESETS', icon: Icons.tune_rounded),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final item = _presets[idx];
                final isSelected = currentPreset == item['id'];
                return GestureDetector(
                  onTap: () => notifier.setEqPreset(
                    item['id'] as String,
                    List<double>.from(item['bands'] as List),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 16,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          // ── 7-Band Sliders ──────────────────────────────────────────────────
          const _Header(title: '7-BAND FREQUENCY SLIDERS', icon: Icons.equalizer_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final gain = i < currentBands.length ? currentBands[i] : 0.0;
                    return Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${gain > 0 ? "+" : ""}${gain.toInt()}dB',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: gain != 0 ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 140,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: AppColors.surfaceMid,
                                  thumbColor: AppColors.primary,
                                  overlayColor: AppColors.primary.withValues(alpha: 0.1),
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: gain.clamp(-12.0, 12.0),
                                  min: -12.0,
                                  max: 12.0,
                                  divisions: 24,
                                  onChanged: (val) => notifier.setEqBand(i, val),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _bandFreqs[i],
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Left / Right Balance ────────────────────────────────────────────
          const _Header(title: 'EARBUD L / R BALANCE', icon: Icons.headphones_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _BalanceSlider(
                  label: 'Left Ear Gain',
                  value: leftBal,
                  icon: Icons.west_rounded,
                  onChanged: (v) => notifier.setBalance(v, rightBal),
                ),
                const Divider(color: AppColors.border, height: 20),
                _BalanceSlider(
                  label: 'Right Ear Gain',
                  value: rightBal,
                  icon: Icons.east_rounded,
                  onChanged: (v) => notifier.setBalance(leftBal, v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── VOX Noise Gate Threshold ───────────────────────────────────────
          const _Header(title: 'VOX NOISE GATE (BACKGROUND CUT)', icon: Icons.noise_control_off_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cutoff Threshold',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      voxThresh == 0.0 ? 'OFF' : '${(voxThresh * 100).toInt()}%',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: voxThresh > 0 ? AppColors.secondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Automatically mutes audio when background noise is below threshold.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: voxThresh,
                  min: 0.0,
                  max: 0.5,
                  divisions: 20,
                  activeColor: AppColors.secondary,
                  inactiveColor: AppColors.surfaceMid,
                  onChanged: (v) => notifier.setVoxThreshold(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final IconData icon;
  const _Header({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _BalanceSlider extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final ValueChanged<double> onChanged;

  const _BalanceSlider({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceMid,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        Text(
          '${(value * 100).toInt()}%',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
