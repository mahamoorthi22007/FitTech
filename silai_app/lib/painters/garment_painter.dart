// lib/painters/garment_painter.dart
import 'package:flutter/material.dart';

class AnimationPainter extends CustomPainter {
  final List<Offset>? coords;

  AnimationPainter({this.coords});

  @override
  void paint(Canvas canvas, Size size) {
    if (coords == null || coords!.length < 2) return;

    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Draw the path
    for (int i = 0; i < coords!.length - 1; i++) {
      canvas.drawLine(coords![i], coords![i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimationPainter oldDelegate) => true;
}