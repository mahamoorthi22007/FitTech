import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:silai_app/theme/app_theme.dart';

/// Wraps the raw blueprint SVG and overlays an animated glow that pulses
/// over the line type matching the current narration step:
///   - 'outline' / 'finish' -> glow the solid blue OUTER cut line
///   - 'curve'              -> glow the blue line with a moving sweep
///   - 'pin' / 'stitch'     -> glow the dashed red INNER stitch line
///
/// We don't rewrite the SVG string itself (keeps the server's drafting
/// engine untouched); instead we draw a semi-transparent colored overlay
/// using the same viewBox, and pulse its opacity. This keeps the real
/// pattern crisp while still giving a clear animated highlight.
class BlueprintGlowOverlay extends StatefulWidget {
  final String svgString;
  final String currentHighlight; // 'outline' | 'curve' | 'pin' | 'stitch' | 'finish'
  final double height;

  const BlueprintGlowOverlay({
    Key? key,
    required this.svgString,
    required this.currentHighlight,
    this.height = 220,
  }) : super(key: key);

  @override
  State<BlueprintGlowOverlay> createState() => _BlueprintGlowOverlayState();
}

class _BlueprintGlowOverlayState extends State<BlueprintGlowOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.25, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _glowColor {
    switch (widget.currentHighlight) {
      case 'pin':
      case 'stitch':
        return const Color(0xFFD93025); // matches server's dashed stitch-line red
      case 'outline':
      case 'curve':
      case 'finish':
      default:
        return const Color(0xFF1A73E8); // matches server's solid cut-line blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The real blueprint, untouched.
          SvgPicture.string(
            widget.svgString,
            placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
          ),

          // Animated highlight ring that pulses around the active line type.
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _glowColor.withOpacity(_pulse.value * 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: _glowColor.withOpacity(_pulse.value),
                      width: 2.4,
                    ),
                  ),
                ),
              );
            },
          ),

          // Small legend chip showing which line is currently "live".
          Positioned(
            bottom: 6,
            right: 6,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _glowColor.withOpacity(0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _glowColor.withOpacity(_pulse.value),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _legendText,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.espresso),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _legendText {
    switch (widget.currentHighlight) {
      case 'pin':
        return 'Pinning seam';
      case 'stitch':
        return 'Stitch line (red)';
      case 'curve':
        return 'Curved cut';
      case 'finish':
        return 'Final check';
      case 'outline':
      default:
        return 'Cut line (blue)';
    }
  }
}