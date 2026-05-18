// lib/presentation/widgets/status_badge.dart
// LIVE / CONNECTING / STOPPED animated status chip

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/sharing_state.dart';

class StatusBadge extends StatefulWidget {
  final SharingStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (color, label, pulse) = _config(widget.status);

    final dot = Container(
      width:  8,
      height: 8,
      decoration: BoxDecoration(
        color:  color,
        shape:  BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
      ),
    );

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color:      color,
              letterSpacing: 1.5,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );

    if (!pulse) return badge;

    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(opacity: _opacity.value, child: badge),
    );
  }

  (Color, String, bool) _config(SharingStatus status) {
    switch (status) {
      case SharingStatus.live:
        return (AppColors.liveGreen, 'LIVE', true);
      case SharingStatus.connecting:
        return (AppColors.warningAmber, 'CONNECTING', true);
      case SharingStatus.error:
        return (AppColors.errorRed, 'ERROR', false);
      case SharingStatus.stopped:
        return (AppColors.textSecondary, 'STOPPED', false);
    }
  }
}
