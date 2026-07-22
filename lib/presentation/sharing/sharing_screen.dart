import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../providers/audio_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/recording_provider.dart';
import '../../providers/tts_provider.dart';
import '../widgets/waveform_widget.dart';
import '../widgets/audio_level_indicator.dart';
import '../widgets/status_badge.dart';
import '../widgets/bt_device_card.dart';

class SharingScreen extends ConsumerWidget {
  const SharingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(audioSharingProvider);
    final btDevice = ref.watch(bluetoothProvider).valueOrNull;

    final scaffoldBg    = AppColors.getScaffoldBg(context);
    final textPrimary   = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Live Sharing', style: TextStyle(color: textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              const SizedBox(height: 12),
              StatusBadge(status: state.status),
              const SizedBox(height: 36),
              _LiveOrb(audioLevel: state.audioLevel, isLive: state.isLive),
              const SizedBox(height: 28),
              Text(
                state.activeDuration.toHms(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'ACTIVE DURATION',
                style: TextStyle(
                  fontFamily: 'Outfit', fontSize: 10, letterSpacing: 2,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              _WaveformCard(audioLevel: state.audioLevel, isLive: state.isLive),
              const SizedBox(height: 16),
              BtDeviceCard(
                device: btDevice,
                onRefresh: () => ref.read(bluetoothProvider.notifier).refresh(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _InfoCard(
                    label: 'AUDIO LEVEL',
                    value: '${(state.audioLevel * 100).toStringAsFixed(0)}%',
                    icon: Icons.graphic_eq_rounded,
                    color: AppColors.liveGreen,
                  )),
                  const SizedBox(width: 12),
                  const Expanded(child: _InfoCard(
                    label: 'LATENCY MODE',
                    value: 'LOW',
                    icon: Icons.speed_rounded,
                    color: AppColors.primary,
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final dir = await getApplicationDocumentsDirectory();
                          final recDir = Directory('${dir.path}/spyear_recordings');
                          if (!await recDir.exists()) {
                            await recDir.create(recursive: true);
                          }
                          final timestamp = DateTime.now().millisecondsSinceEpoch;
                          final file = File('${recDir.path}/Recording_$timestamp.m4a');
                          await file.writeAsString('Audio clip recorded at ${DateTime.now()}');
                          await ref.read(recordingProvider.notifier).loadRecordings();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎙️ Audio clip saved to Recordings!'),
                                backgroundColor: AppColors.liveGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving clip: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.fiber_manual_record_rounded, color: Colors.redAccent, size: 18),
                      label: const Text('Record Clip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceMid,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(timeAnnouncementProvider.notifier).announceNow(),
                      icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                      label: const Text('Announce Time'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(audioSharingProvider.notifier).stopSharing();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.stop_rounded, color: Colors.white),
                  label: const Text('Stop Sharing',
                      style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700,
                          fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveOrb extends StatefulWidget {
  final double audioLevel;
  final bool isLive;
  const _LiveOrb({required this.audioLevel, required this.isLive});

  @override
  State<_LiveOrb> createState() => _LiveOrbState();
}

class _LiveOrbState extends State<_LiveOrb> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.isLive ? AppColors.liveGreen : AppColors.primary;
    final size  = 130.0 + widget.audioLevel * 30;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size + 50, height: size + 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: _ctrl.value * 0.2)),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                color.withValues(alpha: 0.25 + widget.audioLevel * 0.3),
                AppColors.scaffoldBg,
              ]),
              border: Border.all(color: color, width: 2.5),
              boxShadow: [BoxShadow(
                color: color.withValues(alpha: 0.3 + widget.audioLevel * 0.3),
                blurRadius: 30, spreadRadius: 5,
              )],
            ),
            child: Icon(
              widget.isLive ? Icons.mic_rounded : Icons.mic_off_rounded,
              color: color, size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformCard extends StatelessWidget {
  final double audioLevel;
  final bool isLive;
  const _WaveformCard({required this.audioLevel, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final surfaceBg     = AppColors.getSurfaceBg(context);
    final border        = AppColors.getBorder(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.mic_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text('MICROPHONE INPUT',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                    fontWeight: FontWeight.w600, color: textSecondary,
                    letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 14),
          WaveformWidget(
            audioLevel: audioLevel, isActive: isLive, height: 72,
            color: isLive ? AppColors.liveGreen : AppColors.primary,
          ),
          const SizedBox(height: 14),
          AudioLevelIndicator(level: audioLevel),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InfoCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final surfaceBg     = AppColors.getSurfaceBg(context);
    final border        = AppColors.getBorder(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontFamily: 'Outfit', fontSize: 22,
            fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 10,
            fontWeight: FontWeight.w500, color: textSecondary,
            letterSpacing: 1.3)),
      ]),
    );
  }
}
