// lib/presentation/widgets/waveform_widget.dart
// Animated microphone waveform using CustomPainter

import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Animated waveform that reacts to audio level (0.0 – 1.0)
class WaveformWidget extends StatefulWidget {
  final double audioLevel;
  final bool isActive;
  final double width;
  final double height;
  final Color color;

  const WaveformWidget({
    super.key,
    required this.audioLevel,
    required this.isActive,
    this.width  = double.infinity,
    this.height = 80,
    this.color  = AppColors.primary,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<double> _bars = List.generate(28, (_) => 0.1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateBars)..repeat();
  }

  void _updateBars() {
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _bars.length; i++) {
        if (widget.isActive) {
          // Organic random wave based on audio level
          final base  = widget.audioLevel * 0.7;
          final noise = (_random.nextDouble() - 0.5) * 0.4 * widget.audioLevel;
          _bars[i] = (base + noise).clamp(0.05, 1.0);
        } else {
          // Idle — gentle pulse
          _bars[i] = 0.05 + sin(_controller.value * 2 * pi + i * 0.4) * 0.03;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _WaveformPainter(
          bars:      _bars,
          color:     widget.color,
          isActive:  widget.isActive,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final Color color;
  final bool isActive;

  _WaveformPainter({
    required this.bars,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final barWidth  = size.width / (bars.length * 1.6);
    final gap       = barWidth * 0.6;
    final totalW    = bars.length * (barWidth + gap) - gap;
    double x        = (size.width - totalW) / 2;

    for (int i = 0; i < bars.length; i++) {
      final barH = bars[i] * size.height;
      final yTop = (size.height - barH) / 2;

      // Gradient per bar — brighter at center
      final distFromCenter = (i - bars.length / 2).abs() / (bars.length / 2);
      final opacity = isActive
          ? (1.0 - distFromCenter * 0.4).clamp(0.5, 1.0)
          : 0.3;

      paint.color = color.withValues(alpha: opacity);

      // Glow shadow
      if (isActive && bars[i] > 0.3) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 1, yTop - 2, barWidth + 2, barH + 4),
            const Radius.circular(4),
          ),
          Paint()..color = color.withValues(alpha: 0.2) ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, yTop, barWidth, barH),
          const Radius.circular(3),
        ),
        paint,
      );

      x += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}
