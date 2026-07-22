// lib/presentation/widgets/bt_device_card.dart
// Bluetooth device status card widget

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/bluetooth_device_entity.dart';

class BtDeviceCard extends StatelessWidget {
  final BluetoothDeviceEntity? device;
  final VoidCallback? onRefresh;

  const BtDeviceCard({
    super.key,
    this.device,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected   = device?.isConnected ?? false;
    final surfaceBg     = AppColors.getSurfaceBg(context);
    final surfaceMid    = AppColors.getSurfaceMid(context);
    final textPrimary   = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border        = AppColors.getBorder(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? AppColors.primary.withValues(alpha: 0.4) : border,
        ),
      ),
      child: Row(
        children: [
          // BT Icon with glow
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : surfaceMid,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _deviceIcon(device?.type),
              color: isConnected ? AppColors.primary : textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? (device!.name) : 'No Device Connected',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isConnected ? textPrimary : textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isConnected
                      ? _profileLabel(device!.type)
                      : 'Pair Bluetooth earbuds to start',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status dot + refresh
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? AppColors.liveGreen : textSecondary,
                  boxShadow: isConnected
                      ? [BoxShadow(color: AppColors.liveGreen.withValues(alpha: 0.5), blurRadius: 6)]
                      : null,
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRefresh,
                  child: Icon(Icons.refresh_rounded, size: 18, color: textSecondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _deviceIcon(BluetoothDeviceType? type) {
    switch (type) {
      case BluetoothDeviceType.headset:    return Icons.headset_mic_rounded;
      case BluetoothDeviceType.headphones: return Icons.headphones_rounded;
      case BluetoothDeviceType.speaker:    return Icons.speaker_rounded;
      default:                              return Icons.bluetooth_rounded;
    }
  }

  String _profileLabel(BluetoothDeviceType type) {
    switch (type) {
      case BluetoothDeviceType.headset:    return 'Headset (HFP) — Low latency';
      case BluetoothDeviceType.headphones: return 'Headphones (A2DP) — High quality';
      case BluetoothDeviceType.speaker:    return 'Bluetooth Speaker';
      default:                              return 'Bluetooth Audio';
    }
  }
}
