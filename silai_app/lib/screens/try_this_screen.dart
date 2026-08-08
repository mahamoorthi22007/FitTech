import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'blueprint_screen.dart';

class TryThisScreen extends StatefulWidget {
  final String imageUrl;
  final String designName;
  final String category;

  const TryThisScreen({
    super.key,
    required this.imageUrl,
    required this.designName,
    required this.category,
  });

  @override
  State<TryThisScreen> createState() => _TryThisScreenState();
}

class _TryThisScreenState extends State<TryThisScreen> with TickerProviderStateMixin {
  int _step = 0; // 0=confirm, 1=measurements, 2=fabric
  late AnimationController _checkAnim;
  late Animation<double> _checkScale;
  final Map<String, TextEditingController> _ctrl = {};

  final _fields = [
    {'key': 'shoulder', 'label': 'Shoulder Width', 'icon': '📏'},
    {'key': 'bust', 'label': 'Bust / Chest', 'icon': '📐'},
    {'key': 'waist', 'label': 'Waist', 'icon': '📏'},
    {'key': 'hip', 'label': 'Hip', 'icon': '📐'},
    {'key': 'sleeve', 'label': 'Sleeve Length', 'icon': '📏'},
    {'key': 'length', 'label': 'Dress Length', 'icon': '📐'},
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) _ctrl[f['key']!] = TextEditingController();
    _checkAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _checkScale = CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _checkAnim.dispose();
    for (final c in _ctrl.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
          child: child,
        ),
        child: [
          _StepConfirm(key: const ValueKey(0), imageUrl: widget.imageUrl, designName: widget.designName, onYes: () => setState(() => _step = 1), onNo: () => Navigator.pop(context)),
          _StepMeasure(key: const ValueKey(1), fields: _fields, controllers: _ctrl, designName: widget.designName, onNext: () { _checkAnim.forward(); setState(() => _step = 2); }),
          _StepFabric(key: const ValueKey(2), checkAnim: _checkScale, designName: widget.designName, category: widget.category, controllers: _ctrl),
        ][_step],
      ),
    );
  }
}

// ─── Step 0: Confirm ──────────────────────────────────────────────────────────
class _StepConfirm extends StatefulWidget {
  final String imageUrl, designName;
  final VoidCallback onYes, onNo;
  const _StepConfirm({super.key, required this.imageUrl, required this.designName, required this.onYes, required this.onNo});

  @override
  State<_StepConfirm> createState() => _StepConfirmState();
}

class _StepConfirmState extends State<_StepConfirm> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _slideUp = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen image
        Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.dustyRose,
            child: const Center(child: Text('🪡', style: TextStyle(fontSize: 80))),
          ),
        ),

        // Dark gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x44000000), Color(0xCC3D2B1F)],
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 52, left: 16,
          child: GestureDetector(
            onTap: widget.onNo,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),

        // Bottom card
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(_slideUp),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Text('✦', style: TextStyle(fontSize: 20, color: AppColors.terracotta)),
                  const SizedBox(height: 8),
                  Text(
                    'Do you want to try\n"${widget.designName}"?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.espresso, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  const Text('We\'ll create a stitching blueprint\nperfect for your measurements', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onNo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Not now', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: widget.onYes,
                          child: const Text('Yes, let\'s stitch! →', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Step 1: Measurements ─────────────────────────────────────────────────────
class _StepMeasure extends StatelessWidget {
  final List<Map<String, String>> fields;
  final Map<String, TextEditingController> controllers;
  final String designName;
  final VoidCallback onNext;

  const _StepMeasure({super.key, required this.fields, required this.controllers, required this.designName, required this.onNext});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Your Measurements'),
          leading: BackButton(color: AppColors.brick, onPressed: () => Navigator.pop(context)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Design preview chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppColors.dustyRose, borderRadius: BorderRadius.circular(22)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('✦ ', style: TextStyle(color: AppColors.brick, fontWeight: FontWeight.w700)),
                  Text(designName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brick)),
                ]),
              ),
              const SizedBox(height: 16),
              const Text('Enter your measurements', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.espresso)),
              const SizedBox(height: 4),
              const Text('All in centimetres (cm). These help us create the perfect blueprint for you.', style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5)),
              const SizedBox(height: 18),

              // Measurement fields in card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: List.generate(fields.length, (i) {
                    final f = fields[i];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Text(f['icon']!, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(f['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.espresso))),
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: controllers[f['key']],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: '0.0',
                                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.iconMuted),
                                    suffixText: 'cm',
                                    suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.espresso),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < fields.length - 1) const Divider(color: AppColors.divider, height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [
                  Text('📷 ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text('You can also upload a full-length photo for auto measurement detection in the next step.', style: TextStyle(fontSize: 11, color: AppColors.walnut, height: 1.5))),
                ]),
              ),

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Generate Blueprint →', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      );
}

// ─── Step 2: Fabric choice then go to Blueprint ───────────────────────────────
class _StepFabric extends StatefulWidget {
  final Animation<double> checkAnim;
  final String designName, category;
  final Map<String, TextEditingController> controllers;
  const _StepFabric({super.key, required this.checkAnim, required this.designName, required this.category, required this.controllers});

  @override
  State<_StepFabric> createState() => _StepFabricState();
}

class _StepFabricState extends State<_StepFabric> {
  int _selFabric = 0;

  final _fabrics = [
    {'emoji': '🌿', 'name': 'Cotton', 'note': 'Breathable, daily wear'},
    {'emoji': '✨', 'name': 'Silk', 'note': 'Elegant, occasions'},
    {'emoji': '💎', 'name': 'Georgette', 'note': 'Flowy, semi-formal'},
    {'emoji': '🌸', 'name': 'Chanderi', 'note': 'Lightweight, festive'},
    {'emoji': '🍃', 'name': 'Linen', 'note': 'Natural, summer'},
    {'emoji': '🌺', 'name': 'Organza', 'note': 'Sheer, bridal'},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Choose Fabric'),
          leading: BackButton(color: AppColors.brick, onPressed: () => Navigator.pop(context)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaleTransition(
                scale: widget.checkAnim,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.dustyRose, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: const BoxDecoration(color: AppColors.brick, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Measurements saved!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.espresso)),
                      Text('Now choose fabric for: ${widget.designName}', style: const TextStyle(fontSize: 11, color: AppColors.walnut)),
                    ])),
                  ]),
                ),
              ),
              const SizedBox(height: 22),
              const Text('Select your fabric', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.espresso)),
              const SizedBox(height: 4),
              const Text('AI will calculate the exact fabric quantity needed', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.0),
                itemCount: _fabrics.length,
                itemBuilder: (_, i) {
                  final active = i == _selFabric;
                  return GestureDetector(
                    onTap: () => setState(() => _selFabric = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: active ? AppColors.dustyRose : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: active ? AppColors.terracotta : AppColors.divider, width: active ? 2 : 1),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_fabrics[i]['emoji']!, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 6),
                        Text(_fabrics[i]['name']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? AppColors.brick : AppColors.espresso)),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(_fabrics[i]['note']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppColors.textMuted), maxLines: 2),
                        ),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => BlueprintScreen(dressType: widget.category)),
                  ),
                  child: const Text('Generate My Blueprint ✦', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      );
}
