import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class StitchInstructionsScreen extends StatefulWidget {
  final String dressType;
  final String? tutorialText;      // ✅ Integrated
  final String? audioTrackBase64;  // ✅ Integrated

  const StitchInstructionsScreen({
    super.key, 
    required this.dressType,
    this.tutorialText,             // ✅ Integrated
    this.audioTrackBase64,         // ✅ Integrated
  });

  @override
  State<StitchInstructionsScreen> createState() => _StitchInstructionsScreenState();
}

class _StitchInstructionsScreenState extends State<StitchInstructionsScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  late List<AnimationController> _stepControllers;

  List<_StitchStep> get _steps => _getSteps(widget.dressType);

  @override
  void initState() {
    super.initState();
    _stepControllers = List.generate(
      _steps.length,
      (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 300)),
    );
    _stepControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _stepControllers) c.dispose();
    super.dispose();
  }

  void _goToStep(int i) {
    _stepControllers[_currentStep].reverse();
    setState(() => _currentStep = i);
    _stepControllers[i].forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Stitch: ${widget.dressType}'),
        leading: const BackButton(color: AppColors.brick),
      ),
      body: Column(
        children: [
          _StepHeader(steps: _steps, current: _currentStep, onTap: _goToStep),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim, 
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: _StepContent(
                  step: _steps[_currentStep], 
                  stepIndex: _currentStep,
                  tutorialText: widget.tutorialText, // Passing to content layout if needed
                ),
              ),
            ),
          ),
          _StepNav(
            current: _currentStep,
            total: _steps.length,
            onPrev: _currentStep > 0 ? () => _goToStep(_currentStep - 1) : null,
            onNext: _currentStep < _steps.length - 1 ? () => _goToStep(_currentStep + 1) : null,
          ),
        ],
      ),
    );
  }

  List<_StitchStep> _getSteps(String type) {
    if (type == 'Chudithar' || type == 'Anarkali' || type == 'Kurti') {
      return [
        _StitchStep(title: 'Fabric Prep', emoji: '✂️', desc: 'Wash, dry and iron the fabric. Mark grain lines and fold fabric right sides together.', tips: ['Pre-wash to prevent shrinkage', 'Iron on correct heat setting', 'Mark pattern pieces with chalk']),
        _StitchStep(title: 'Cutting', emoji: '📐', desc: 'Cut front & back body pieces, two sleeve pieces, and collar facing. Add 1.5cm seam allowance on all sides.', tips: ['Cut on grain line', 'Keep pattern pieces pinned while cutting', 'Cut notches for matching']),
        _StitchStep(title: 'Body Stitching', emoji: '🪡', desc: 'Join front and back at shoulder seams. Press seams open. Stitch side seams from underarm to hem.', tips: ['Stitch at 1.5cm seam allowance', 'Backstitch at start & end', 'Press seams as you go']),
        _StitchStep(title: 'Sleeves', emoji: '💪', desc: 'Stitch underarm seam of sleeve. Ease the sleeve cap and attach to armhole. Press towards sleeve.', tips: ['Ease carefully — don\'t stretch', 'Clip curves after stitching', 'Press with sleeve on tailor\'s ham']),
        _StitchStep(title: 'Neck Finishing', emoji: '🔘', desc: 'Stay-stitch neckline. Attach neck facing and understitch. For collar: fold, stitch & turn.', tips: ['Stay-stitch 6mm from edge', 'Grade seam allowances', 'Under-stitch for clean finish']),
        _StitchStep(title: 'Hem & Finishing', emoji: '✨', desc: 'Turn up hem 2cm, press & stitch. Trim threads. Final press with steam for crisp finish.', tips: ['Even hem all around', 'Steam press for professional finish', 'Remove all basting threads']),
      ];
    } else if (type == 'Saree Blouse') {
      return [
        _StitchStep(title: 'Cutting', emoji: '✂️', desc: 'Cut front, back, two side panels and sleeve pieces. Transfer all markings.', tips: ['Mark darts carefully', 'Cut on bias for back if needed']),
        _StitchStep(title: 'Darts', emoji: '📌', desc: 'Stitch bust darts for shaping. Press towards waist side seam.', tips: ['Mark dart apex precisely', 'Taper to nothing at tip']),
        _StitchStep(title: 'Side Seams', emoji: '🪡', desc: 'Join front and back side seams. Try on for fit and adjust before continuing.', tips: ['Do fitting before permanent stitch']),
        _StitchStep(title: 'Neck & Back', emoji: '🔘', desc: 'Finish neckline and back opening. Attach hooks and bars or string for closure.', tips: ['Interface neck edge', 'Use blouse hooks for secure closure']),
        _StitchStep(title: 'Sleeves', emoji: '💪', desc: 'Stitch and attach sleeves. Finish with rolled hem or facing.', tips: ['Match sleeve to armhole carefully']),
        _StitchStep(title: 'Final Finish', emoji: '✨', desc: 'Hem all edges. Check all closures. Final steam press.', tips: ['Check for any skipped stitches', 'Press with press cloth on silk']),
      ];
    } else {
      return [
        _StitchStep(title: 'Preparation', emoji: '✂️', desc: 'Prepare fabric and transfer pattern markings.', tips: ['Pre-wash fabric']),
        _StitchStep(title: 'Cutting', emoji: '📐', desc: 'Cut all pattern pieces with seam allowance.', tips: ['Cut accurately']),
        _StitchStep(title: 'Assembly', emoji: '🪡', desc: 'Stitch all main seams as per blueprint.', tips: ['Press seams open']),
        _StitchStep(title: 'Finishing', emoji: '✨', desc: 'Hem, press and inspect the finished garment.', tips: ['Final press for professional look']),
      ];
    }
  }
}

class _StitchStep {
  final String title, emoji, desc;
  final List<String> tips;
  const _StitchStep({required this.title, required this.emoji, required this.desc, required this.tips});
}

class _StepHeader extends StatelessWidget {
  final List<_StitchStep> steps;
  final int current;
  final ValueChanged<int> onTap;
  const _StepHeader({required this.steps, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: List.generate(steps.length, (i) {
              final active = i == current;
              final done = i < current;
              return GestureDetector(
                onTap: () => onTap(i),
                child: Row(
                  children: [
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: done ? AppColors.terracotta : active ? AppColors.brick : AppColors.blushLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: active ? AppColors.brick : done ? AppColors.terracotta : AppColors.divider),
                          ),
                          child: Center(child: done ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white) : Text(steps[i].emoji, style: const TextStyle(fontSize: 16))),
                        ),
                        const SizedBox(height: 4),
                        Text(steps[i].title, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? AppColors.brick : AppColors.textMuted)),
                      ],
                    ),
                    if (i < steps.length - 1) Container(width: 20, height: 1, margin: const EdgeInsets.only(bottom: 16, left: 2, right: 2), color: done ? AppColors.terracotta : AppColors.divider),
                  ],
                ),
              );
            }),
          ),
        ),
      );
}

class _StepContent extends StatelessWidget {
  final _StitchStep step;
  final int stepIndex;
  final String? tutorialText; // ✅ Field added to access raw instructions text

  const _StepContent({
    super.key, 
    required this.step, 
    required this.stepIndex, 
    this.tutorialText,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VideoPlaceholder(emoji: step.emoji, title: step.title),
            const SizedBox(height: 16),
            Text('Step ${stepIndex + 1}: ${step.title}', style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.espresso)),
            const SizedBox(height: 10),
            Text(step.desc, style: const TextStyle(fontSize: 14, color: AppColors.walnut, height: 1.65)),
            
            // ✅ Optional: If you want to show the custom generated tutorial text alongside the step description
            if (tutorialText != null && stepIndex == 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blushLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Custom Note:\n$tutorialText',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.espresso),
                ),
              ),
            ],

            const SizedBox(height: 18),
            const Text('PRO TIPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brick, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            ...step.tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 10), decoration: const BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle)),
                      Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: AppColors.espresso, height: 1.5))),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            _PhotoGallery(),
          ],
        ),
      );
}

class _VideoPlaceholder extends StatelessWidget {
  final String emoji, title;
  const _VideoPlaceholder({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.dustyRose,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 60)),
            Positioned(
              bottom: 14, left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.espresso.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                child: Text(title, style: const TextStyle(fontSize: 11, color: AppColors.white, fontWeight: FontWeight.w500)),
              ),
            ),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.white.withOpacity(0.9), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, size: 32, color: AppColors.brick),
            ),
          ],
        ),
      );
}

class _PhotoGallery extends StatelessWidget {
  final _photos = const ['✂️ Cutting', '📌 Pinning', '🪡 Stitching'];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STEP PHOTOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brick, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Row(
            children: _photos.map((p) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    height: 72,
                    decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                    child: Center(child: Text(p, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center)),
                  ),
                )).toList(),
          ),
        ],
      );
}

class _StepNav extends StatelessWidget {
  final int current, total;
  final VoidCallback? onPrev, onNext;
  const _StepNav({required this.current, required this.total, this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        color: AppColors.white,
        child: Row(
          children: [
            if (onPrev != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left_rounded, size: 18),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brick,
                    side: const BorderSide(color: AppColors.brick),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            if (onPrev != null && onNext != null) const SizedBox(width: 10),
            if (onNext != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNext,
                  icon: const Text('Next'),
                  label: const Icon(Icons.chevron_right_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brick,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            if (onNext == null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Done! 🎉'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
          ],
        ),
      );
}