// lib/presentation/home/home_screen.dart
// Main home screen — shows BT status, mic card, and Start Sharing button

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/audio_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../domain/entities/sharing_state.dart';
import '../../domain/entities/audio_settings.dart';
import '../sharing/sharing_screen.dart';
import '../settings/settings_screen.dart';
import '../stealth/stealth_screen.dart';
import '../stealth/decoy_calculator_screen.dart';
import '../widgets/bt_device_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/waveform_widget.dart';
import '../widgets/permission_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    if (!micGranted && mounted) {
      await showDialog(
        context: context,
        builder: (_) => PermissionDialog(
          title:          'Microphone Required',
          description:    'SpyEar needs microphone access to stream live audio to your Bluetooth earbuds.',
          permissionName: 'Microphone',
          icon:           Icons.mic_rounded,
          onGrant:        () async {
            Navigator.pop(context);
            await openAppSettings();
          },
          onDeny:         () => Navigator.pop(context),
        ),
      );
      return false;
    }
    return micGranted;
  }

  Future<void> _handleStartSharing() async {
    final granted = await _requestPermissions();
    if (!granted || !mounted) return;

    final notifier = ref.read(audioSharingProvider.notifier);
    await notifier.startSharing();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SharingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharingState = ref.watch(audioSharingProvider);
    final btDevice     = ref.watch(bluetoothProvider).valueOrNull;
    final isBtConnected = ref.watch(isBluetoothConnectedProvider);
    final isLive       = sharingState.isLive;
    final audioSettings = ref.watch(audioSettingsProvider).valueOrNull ?? const AudioSettings();
    final useBluetoothMic = audioSettings.useBluetoothMic;

    final scaffoldBg    = AppColors.getScaffoldBg(context);
    final surfaceBg     = AppColors.getSurfaceBg(context);
    final border        = AppColors.getBorder(context);
    final textPrimary   = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            // App logo
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.headphones_rounded, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            Text('SpyEar', style: TextStyle(color: textPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Status Badge ──────────────────────────────────────────────────
            Center(child: StatusBadge(status: sharingState.status)),
            const SizedBox(height: 32),

            // ── Mic Orb ───────────────────────────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isLive ? AppColors.liveGreen : AppColors.primary)
                                .withValues(alpha: _glowAnimation.value * (isLive ? 0.4 : 0.2)),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isLive ? AppColors.liveGreen : AppColors.primary)
                              .withValues(alpha: _glowAnimation.value * 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    // Core orb
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isLive
                              ? [AppColors.liveGreen.withValues(alpha: 0.3), AppColors.surfaceBg]
                              : [AppColors.primary.withValues(alpha: 0.2), AppColors.surfaceBg],
                        ),
                        border: Border.all(
                          color: isLive ? AppColors.liveGreen : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isLive ? Icons.mic_rounded : Icons.mic_none_rounded,
                        size:  50,
                        color: isLive ? AppColors.liveGreen : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Waveform ──────────────────────────────────────────────────────
            WaveformWidget(
              audioLevel: isLive ? sharingState.audioLevel : 0.0,
              isActive:   isLive,
              height:     64,
              color:      isLive ? AppColors.liveGreen : AppColors.primary,
            ),
            const SizedBox(height: 24),

            // ── Quick Modes Action Bar ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickModeButton(
                    icon: Icons.visibility_off_rounded,
                    label: 'Stealth OLED',
                    color: AppColors.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StealthScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickModeButton(
                    icon: Icons.calculate_rounded,
                    label: 'Decoy Calculator',
                    color: AppColors.warningAmber,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DecoyCalculatorScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── BT Device Card ────────────────────────────────────────────────
            const Text(
              'BLUETOOTH DEVICE',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            BtDeviceCard(
              device: btDevice,
              onRefresh: () => ref.read(bluetoothProvider.notifier).refresh(),
            ),
            const SizedBox(height: 32),

            // ── Microphone Source ──────────────────────────────────────────────
            Text(
              'MICROPHONE SOURCE',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isLive
                          ? null
                          : () => ref.read(audioSettingsProvider.notifier).toggleUseBluetoothMic(true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: useBluetoothMic 
                              ? AppColors.primary.withValues(alpha: isLive ? 0.08 : 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bluetooth_audio_rounded,
                              color: useBluetoothMic 
                                  ? (isLive ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary)
                                  : textSecondary,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AirPods Mic',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: useBluetoothMic 
                                    ? (isLive ? textPrimary.withValues(alpha: 0.6) : textPrimary)
                                    : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: isLive
                          ? null
                          : () => ref.read(audioSettingsProvider.notifier).toggleUseBluetoothMic(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !useBluetoothMic 
                              ? AppColors.primary.withValues(alpha: isLive ? 0.08 : 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.phone_android_rounded,
                              color: !useBluetoothMic 
                                  ? (isLive ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary)
                                  : textSecondary,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone Mic',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !useBluetoothMic 
                                    ? (isLive ? textPrimary.withValues(alpha: 0.6) : textPrimary)
                                    : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Start / Stop Button ───────────────────────────────────────────
            _buildMainButton(sharingState, isBtConnected),
            const SizedBox(height: 16),

            // Subtitle hint
            Center(
              child: Text(
                isLive
                    ? 'Audio is streaming to your earbuds'
                    : (isBtConnected
                        ? 'Tap to stream mic audio to your earbuds'
                        : 'Connect a Bluetooth device to start sharing'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: isLive 
                      ? AppColors.liveGreen 
                      : (isBtConnected ? AppColors.textSecondary : AppColors.warningAmber),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(SharingState state, bool isBtConnected) {
    final isLive       = state.isLive;
    final isConnecting = state.isConnecting;

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isLive
              ? const LinearGradient(
                  colors: [AppColors.errorRed, Color(0xFFCC2233)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (isLive ? AppColors.errorRed : AppColors.primary)
                  .withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isConnecting
                ? null
                : (isLive
                    ? () => ref.read(audioSharingProvider.notifier).stopSharing()
                    : _handleStartSharing),
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: isConnecting
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isLive ? 'Stop Sharing' : 'Start Sharing',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickModeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurfaceBg(context);
    final border  = AppColors.getBorder(context);
    final text    = AppColors.getTextPrimary(context);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
