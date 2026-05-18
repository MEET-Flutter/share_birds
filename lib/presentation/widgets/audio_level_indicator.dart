// lib/presentation/widgets/audio_level_indicator.dart
// Vertical audio level bars — like a VU meter

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Animated vertical VU-meter style audio level indicator
class AudioLevelIndicator extends StatelessWidget {
  final double level;      // 0.0 – 1.0
  final int barCount;
  final double barWidth;
  final double height;

  const AudioLevelIndicator({
    super.key,
    required this.level,
    this.barCount = 12,
    this.barWidth = 4,
    this.height   = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (i) {
        final threshold = i / barCount;
        final isActive  = level > threshold;

        // Color gradient: green → cyan → red at peak
        Color barColor;
        if (i < barCount * 0.6) {
          barColor = AppColors.liveGreen;
        } else if (i < barCount * 0.8) {
          barColor = AppColors.primary;
        } else {
          barColor = AppColors.warningAmber;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width:  barWidth,
          height: isActive ? height * ((i + 1) / barCount) : 4,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: isActive
                ? barColor
                : AppColors.border,
            borderRadius: BorderRadius.circular(2),
            boxShadow: isActive && level > 0.5
                ? [BoxShadow(color: barColor.withValues(alpha: 0.4), blurRadius: 4)]
                : null,
          ),
        );
      }),
    );
  }
}
