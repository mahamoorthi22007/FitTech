import 'package:flutter/material.dart';
import 'package:silai_app/theme/app_theme.dart';

/// Simple animated stick figure that performs a cutting, pinning, or
/// stitching motion depending on [action]. Pure CustomPainter — no image
/// assets needed, so it scales cleanly and stays in sync with narration.
class StickFigureAnimator extends StatefulWidget {
  final String action; // 'outline' | 'curve' | 'pin' | 'stitch' | 'finish'
  final double size;

  const StickFigureAnimator({
    Key? key,
    required this.action,
    this.size = 140,
  }) : super(key: key);

  @override
  State<StickFigureAnimator> createState() => _StickFigureAnimatorState();
}

class _StickFigureAnimatorState extends State<StickFigureAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant StickFigureAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action != widget.action) {
      _controller.reset();
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _StickFigurePainter(
            t: _controller.value,
            action: widget.action,
          ),
        );
      },
    );
  }
}

class _StickFigurePainter extends CustomPainter {
  final double t; // 0.0 -> 1.0 looping animation progress
  final String action;

  _StickFigurePainter({required this.t, required this.action});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = AppColors.espresso
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final toolPaint = Paint()
      ..color = AppColors.brick
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.42;
    final headY = size.height * 0.18;
    final shoulderY = size.height * 0.32;
    final hipY = size.height * 0.62;
    final footY = size.height * 0.92;

    // Head
    canvas.drawCircle(Offset(cx, headY), size.width * 0.085, bodyPaint);

    // Spine
    canvas.drawLine(Offset(cx, headY + size.width * 0.085), Offset(cx, hipY), bodyPaint);

    // Legs (static stance)
    canvas.drawLine(Offset(cx, hipY), Offset(cx - size.width * 0.14, footY), bodyPaint);
    canvas.drawLine(Offset(cx, hipY), Offset(cx + size.width * 0.10, footY), bodyPaint);

    // Table / work surface
    final tablePaint = Paint()
      ..color = AppColors.dustyRose
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final tableY = hipY + size.height * 0.08;
    canvas.drawLine(Offset(cx - size.width * 0.05, tableY), Offset(size.width * 0.95, tableY), tablePaint);

    switch (action) {
      case 'outline':
      case 'curve':
        _paintCuttingMotion(canvas, size, cx, shoulderY, tablePaint: bodyPaint, toolPaint: toolPaint, tableY: tableY);
        break;
      case 'pin':
        _paintPinningMotion(canvas, size, cx, shoulderY, bodyPaint: bodyPaint, toolPaint: toolPaint, tableY: tableY);
        break;
      case 'stitch':
        _paintStitchingMotion(canvas, size, cx, shoulderY, bodyPaint: bodyPaint, toolPaint: toolPaint, tableY: tableY);
        break;
      case 'finish':
        _paintFinishMotion(canvas, size, cx, shoulderY, bodyPaint: bodyPaint, toolPaint: toolPaint, tableY: tableY);
        break;
      default:
        _paintCuttingMotion(canvas, size, cx, shoulderY, tablePaint: bodyPaint, toolPaint: toolPaint, tableY: tableY);
    }
  }

  // Arms moving scissors left-right along the table, snipping motion.
  void _paintCuttingMotion(Canvas canvas, Size size, double cx, double shoulderY,
      {required Paint tablePaint, required Paint toolPaint, required double tableY}) {
    final sweep = (t < 0.5 ? t * 2 : (1 - t) * 2); // ping-pong 0->1->0
    final handX = cx + size.width * (0.10 + sweep * 0.32);
    final handY = tableY - 4;

    // Arm from shoulder to hand
    canvas.drawLine(Offset(cx, shoulderY), Offset(handX, handY), tablePaint);

    // Scissors: two blades that open/close
    final openAmt = (0.5 + 0.5 * (t * 6 % 1 < 0.5 ? (t * 6 % 1) * 2 : (1 - (t * 6 % 1)) * 2)) * 7;
    canvas.drawLine(Offset(handX, handY), Offset(handX + 14, handY - openAmt), toolPaint);
    canvas.drawLine(Offset(handX, handY), Offset(handX + 14, handY + openAmt), toolPaint);
    canvas.drawCircle(Offset(handX, handY), 2.4, toolPaint..style = PaintingStyle.fill);
    toolPaint.style = PaintingStyle.stroke;

    // Cut line trace on the table, growing with sweep
    final dashPaint = Paint()
      ..color = AppColors.terracotta
      ..strokeWidth = 2;
    canvas.drawLine(Offset(cx + size.width * 0.10, tableY), Offset(handX, tableY), dashPaint);
  }

  // One hand holds fabric, other hand pins repeatedly (small up-down jab).
  void _paintPinningMotion(Canvas canvas, Size size, double cx, double shoulderY,
      {required Paint bodyPaint, required Paint toolPaint, required double tableY}) {
    final jab = (t < 0.5 ? t * 2 : (1 - t) * 2) * 10;
    final handX = cx + size.width * 0.30;
    final handY = tableY - 6 - jab;

    canvas.drawLine(Offset(cx, shoulderY), Offset(cx + size.width * 0.10, tableY - 2), bodyPaint); // holding hand
    canvas.drawLine(Offset(cx, shoulderY), Offset(handX, handY), bodyPaint); // pinning hand

    // Pin (small needle line)
    canvas.drawLine(Offset(handX, handY), Offset(handX + 4, handY + 14), toolPaint);
    canvas.drawCircle(Offset(handX, handY), 2, toolPaint..style = PaintingStyle.fill);
    toolPaint.style = PaintingStyle.stroke;
  }

  // Needle moving up and down in a stitching rhythm, thread arc behind it.
  void _paintStitchingMotion(Canvas canvas, Size size, double cx, double shoulderY,
      {required Paint bodyPaint, required Paint toolPaint, required double tableY}) {
    final bob = (t < 0.5 ? t * 2 : (1 - t) * 2) * 16;
    final handX = cx + size.width * 0.26;
    final handY = tableY - 10 - bob;

    canvas.drawLine(Offset(cx, shoulderY), Offset(handX, handY), bodyPaint);

    // Needle
    canvas.drawLine(Offset(handX, handY), Offset(handX, handY + 20), toolPaint);

    // Thread arc trailing
    final threadPaint = Paint()
      ..color = AppColors.terracotta
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..moveTo(handX - 14, tableY)
      ..quadraticBezierTo(handX, handY + 24, handX + 14, tableY);
    canvas.drawPath(path, threadPaint);

    // Stitch dots growing along the seam
    final dotPaint = Paint()..color = AppColors.brick;
    for (double dx = -size.width * 0.10; dx <= size.width * 0.10; dx += 8) {
      if (dx <= (t * size.width * 0.20) - size.width * 0.10) {
        canvas.drawCircle(Offset(handX + dx, tableY), 1.6, dotPaint);
      }
    }
  }

  // Hands smooth the finished piece + small sparkle accents.
  void _paintFinishMotion(Canvas canvas, Size size, double cx, double shoulderY,
      {required Paint bodyPaint, required Paint toolPaint, required double tableY}) {
    final glide = (t < 0.5 ? t * 2 : (1 - t) * 2);
    final handX = cx + size.width * (0.05 + glide * 0.30);

    canvas.drawLine(Offset(cx, shoulderY), Offset(handX, tableY - 4), bodyPaint);
    canvas.drawLine(Offset(cx, shoulderY), Offset(handX - 18, tableY - 4), bodyPaint);

    final sparkle = Paint()
      ..color = AppColors.terracotta
      ..style = PaintingStyle.fill;
    final sparkleOpacity = (0.4 + 0.6 * (1 - (glide - 0.5).abs() * 2)).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(handX + 10, tableY - 16),
      3 * sparkleOpacity,
      sparkle..color = AppColors.terracotta.withOpacity(sparkleOpacity),
    );
  }

  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.action != action;
}