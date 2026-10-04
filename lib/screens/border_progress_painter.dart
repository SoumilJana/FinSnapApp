import 'package:flutter/material.dart';

class BorderProgressPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final Color color;
  final double strokeWidth;

  BorderProgressPainter({
    required this.progress,
    this.borderRadius = 16.0,
    this.color = Colors.blue,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rect = Rect.fromLTWH(strokeWidth/2, strokeWidth/2, size.width - strokeWidth, size.height - strokeWidth);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Draw background border
    final bgPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, bgPaint);

    // Draw progress border
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    
    final metric = metrics.first;
    final extractPath = metric.extractPath(0.0, metric.length * progress);
    
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant BorderProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
