import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:silai_app/theme/app_theme.dart';

class RealisticSewingScene extends StatefulWidget {
  final List<Offset> pathPoints; 
  final String action; 
  final Size canvasSize; 
  final double width;
  final double height;

  const RealisticSewingScene({
    Key? key,
    required this.pathPoints,
    required this.action,
    required this.canvasSize,
    this.width = 220,
    this.height = 190,
  }) : super(key: key);

  @override
  State<RealisticSewingScene> createState() => _RealisticSewingSceneState();
}

class _RealisticSewingSceneState extends State<RealisticSewingScene> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // அனிமேஷன் ஸ்மூத்தாக ஓட 5 வினாடிகள்
    );
    
    if (widget.pathPoints.isNotEmpty) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant RealisticSewingScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // புள்ளிகள் (pathPoints) அல்லது ஆக்ஷன் மாறும்போது பழைய அனிமேஷனை ரீசெட் செய்து மீண்டும் முதலிலிருந்து ஓட வைக்கும்
    if (oldWidget.pathPoints != widget.pathPoints || oldWidget.action != widget.action) {
      _controller.reset();
      if (widget.pathPoints.isNotEmpty) {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8), // தையல் மேஜை வுட் கலர்
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      // ListenableBuilder மூலமாக கன்ட்ரோலர் மாறும்போது ஒவ்வொரு மில்லிசெகண்டிற்கும் ஸ்கிரீனை ரீ-டிரா (Re-draw) செய்ய வைக்கிறோம்!
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: SewingScenePainter(
              pathPoints: widget.pathPoints,
              action: widget.action,
              canvasSize: widget.canvasSize,
              progress: _controller.value, // 💡 0.0 முதல் 1.0 வரை தொடர்ந்து மாறும் அனிமேஷன் மதிப்பு
            ),
          );
        },
      ),
    );
  }
}

class SewingScenePainter extends CustomPainter {
  final List<Offset> pathPoints;
  final String action;
  final Size canvasSize;
  final double progress;

  SewingScenePainter({
    required this.pathPoints,
    required this.action,
    required this.canvasSize,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pathPoints.isEmpty) return;

    // 1. தையல் மேஜை மர வேலைப்பாடு மற்றும் துணியின் பின்னணியை வரைதல்
    final bgPaint = Paint()..color = const Color(0xFFF5F5F5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // துணி போன்ற ஒரு லேயர் போடுதல்
    final fabricPaint = Paint()..color = const Color(0xFFE0F7FA).withOpacity(0.5); // லேசான நீல நிறத் துணி
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), const Radius.circular(4)), fabricPaint);

    // 2. ப்ளூபிரிண்ட் புள்ளிகளை தையல் விட்ஜெட்டின் அளவுக்கேற்ப ஸ்கேல் (Scale) செய்தல்
    List<Offset> scaledPoints = [];
    // கேன்வாஸ் சைஸ் பூஜ்ஜியமாக இருந்தால் டிஃபால்ட்டாக 300 எடுத்துக் கொள்ளும்
    final refWidth = canvasSize.width > 0 ? canvasSize.width : 300.0;
    final refHeight = canvasSize.height > 0 ? canvasSize.height : 300.0;
    
    final scaleX = size.width / refWidth;
    final scaleY = size.height / refHeight;

    for (var pt in pathPoints) {
      // சென்டரிங் மற்றும் ஸ்கேலிங் ஆஃப்செட் திருத்தம்
      scaledPoints.add(Offset(pt.dx * scaleX * 0.7 + 25, pt.dy * scaleY * 0.7 + 25));
    }

    if (scaledPoints.length < 2) return;

    // 3. வெட்டப்படும் அல்லது தைக்கப்படும் தையல் தடம் (Trail Pattern Line) வரைதல்
    final pathPaint = Paint()
      ..color = AppColors.brick.withOpacity(0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    for (int i = 1; i < scaledPoints.length; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
    }
    canvas.drawPath(path, pathPaint);

    // நீல நிற தையல் நூல் தடம் (தைத்த பிறகு வரும் கோடு)
    if (action == 'stitch') {
      final stitchTrailPaint = Paint()
        ..color = Colors.blue.shade700
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
        
      final stitchPath = Path();
      stitchPath.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
      
      int currentLimit = (progress * (scaledPoints.length - 1)).floor();
      for (int i = 1; i <= currentLimit; i++) {
        stitchPath.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
      }
      canvas.drawPath(stitchPath, stitchTrailPaint);
    }

    // 4. தற்போதைய அனிமேஷன் பிராக்ரஸ் (Progress) படி டூலின் லொகேஷனைக் கணக்கிடுதல்
    int totalSegments = scaledPoints.length - 1;
    double targetIndexDouble = progress * totalSegments;
    int currentIndex = targetIndexDouble.floor();
    if (currentIndex >= totalSegments) currentIndex = totalSegments - 1;
    double segmentProgress = targetIndexDouble - currentIndex;

    Offset p1 = scaledPoints[currentIndex];
    Offset p2 = scaledPoints[currentIndex + 1];
    
    // லீனியர் இன்டர்போலேஷன் (Interpolated Tool Position)
    Offset toolPosition = Offset(
      p1.dx + (p2.dx - p1.dx) * segmentProgress,
      p1.dy + (p2.dy - p1.dy) * segmentProgress,
    );

    // டூல் நகர வேண்டிய கோணம் (Angle/Rotation)
    double angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);

    // 5. ஆக்ஷனுக்கு ஏற்றவாறு கருவிகளை (Scissors/Needle) வரைதல்
    if (action == 'stitch') {
      _paintNeedle(canvas, toolPosition, angle);
    } else if (action == 'pin') {
      _paintPin(canvas, toolPosition, angle);
    } else {
      _paintScissors(canvas, toolPosition, angle);
    }
  }

  void _paintScissors(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    // கத்தரிக்கோல் கட் செய்வது போன்ற லைவ் பிளேடு மூவ்மென்ட் எஃபெக்ட்
    final bladeAngle = 0.25 * math.sin(progress * 50 * math.pi).abs();

    final scissorPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final handlePaint = Paint()
      ..color = AppColors.brick
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // மேல்பக்க பிளேடு மற்றும் பிடிமானம்
    canvas.save();
    canvas.rotate(-bladeAngle);
    canvas.drawLine(const Offset(-20, -2), const Offset(15, -1), scissorPaint);
    canvas.drawCircle(const Offset(-24, -6), 5, handlePaint);
    canvas.restore();

    // கீழ்ப்பக்க பிளேடு மற்றும் பிடிமானம்
    canvas.save();
    canvas.rotate(bladeAngle);
    canvas.drawLine(const Offset(-20, 3), const Offset(15, 1), scissorPaint);
    canvas.drawCircle(const Offset(-24, 6), 5, handlePaint);
    canvas.restore();

    canvas.restore();
  }

  void _paintNeedle(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle + math.pi / 2);

    final needlePaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // ஊசி துணியில் மேலே கீழே குத்தி குத்தி தைப்பது போன்ற அனிமேஷன் எஃபெக்ட்
    final bobbing = math.sin(progress * 80 * math.pi) * 5;
    canvas.drawLine(Offset(0, -18 + bobbing), Offset(0, 4 + bobbing), needlePaint);
    
    // தையல் நூல் வாலாட்டம்
    final threadPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(0, -12 + bobbing), 1.5, threadPaint);

    canvas.restore();
  }

  void _paintPin(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final pinPaint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), pinPaint);
    canvas.drawCircle(const Offset(-12, 0), 4, Paint()..color = Colors.red.shade700);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SewingScenePainter oldDelegate) {
    // ப்ராக்ரஸ் மாறும் போதெல்லாம் ஸ்கிரீனை கட்டாயம் ரீ-பெயிண்ட் செய்ய வைக்கும் மிக முக்கியமான கண்டிஷன்!
    return true; 
  }
}