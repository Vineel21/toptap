import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashedCirclePainter extends CustomPainter {
  final double progress;

  DashedCirclePainter(this.progress) : super();

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final double strokeWidth =
        4.0; // Slightly thicker for better visibility

    // Background circle (white/gray)
    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Progress circle (red)
    final Paint progressPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(radius, radius);
    final double circleRadius = radius - strokeWidth / 2;

    // Draw background circle
    canvas.drawCircle(
        center, circleRadius, backgroundPaint);

    // Draw progress arc (smooth red flow without gaps)
    if (progress > 0) {
      final double sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(
            center: center, radius: circleRadius),
        -math.pi / 2, // Start at top (12 o'clock)
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
