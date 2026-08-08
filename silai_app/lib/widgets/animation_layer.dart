import 'package:flutter/material.dart';

class AnimationPainter extends CustomPainter {
  final String type;
  final Map<String, dynamic> coords;

  AnimationPainter({required this.type, required this.coords});

  @override
  void paint(Canvas canvas, Size size) {
    if (type == "scissor_cut") {
      final paint = Paint()..color = Colors.red..strokeWidth = 4;
      // Draw a dashed line based on coords
      canvas.drawLine(Offset(coords['start'][0], coords['start'][1]), 
                      Offset(coords['end'][0], coords['end'][1]), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}