import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'stitch_instructions_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _categories = ['All', 'Beginner', 'Intermediate', 'Blouse', 'Chudithar', 'Pants', 'Kids'];

  final _tutorials = [
    _Tutorial(emoji: '👗', title: 'Stitch a Basic Chudithar from Scratch', category: 'Chudithar', level: 'Beginner', duration: '42 min', rating: '4.9', views: '12k', description: 'Complete step-by-step guide from cutting to finishing'),
    _Tutorial(emoji: '🥻', title: 'Designer Blouse with Back Patterns', category: 'Blouse', level: 'Intermediate', duration: '1h 10m', rating: '4.8', views: '8.4k', description: 'Learn to stitch beautiful designer blouses with decorative back'),
    _Tutorial(emoji: '👖', title: 'Tailored Trousers — Perfect Fit Guide', category: 'Pants', level: 'Intermediate', duration: '55 min', rating: '4.7', views: '6.1k', description: 'Professional trouser stitching with adjustable fit'),
    _Tutorial(emoji: '👘', title: 'Kids Frock — Simple & Quick', category: 'Kids', level: 'Beginner', duration: '28 min', rating: '5.0', views: '15k', description: 'Easy children\'s frock perfect for first-time tailors'),
    _Tutorial(emoji: '🎀', title: 'Pattu Pavadai for Kids', category: 'Kids', level: 'Intermediate', duration: '1h 05m', rating: '4.9', views: '9.7k', description: 'Traditional South Indian silk skirt with blouse'),
    _Tutorial(emoji: '✂️', title: 'Basics of Taking Body Measurements', category: 'Beginner', level: 'Beginner', duration: '15 min', rating: '5.0', views: '22k', description: 'Essential first step — learn correct measurement techniques'),
    _Tutorial(emoji: '🪡', title: 'Machine Setup & Stitch Types', category: 'Beginner', level: 'Beginner', duration: '20 min', rating: '4.8', views: '18k', description: 'Threading, tension settings, and all basic stitch types'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Learn Tailoring'),
        leading: const BackButton(color: AppColors.brick),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                  child: const Text('Master the art of stitching\nfrom beginner to expert', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.espresso, height: 1.3)),
                ),
                const SizedBox(height: 16),
                _LearningPathBanner(),
                const SectionLabel('Categories'),
                FilterChipRow(items: _categories),
                const SectionLabel('📺 Video Tutorials'),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _TutorialCard(tutorial: _tutorials[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StitchInstructionsScreen(dressType: _tutorials[i].category)))),
              childCount: _tutorials.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('🎯 Quick Reference Guides'),
                _QuickGuideGrid(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tutorial {
  final String emoji, title, category, level, duration, rating, views, description;
  const _Tutorial({required this.emoji, required this.title, required this.category, required this.level, required this.duration, required this.rating, required this.views, required this.description});
}

class _LearningPathBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.dustyRose,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Your Journey ✦', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.espresso)),
                  SizedBox(height: 6),
                  Text('Follow the beginner path: Measurements → Cutting → Basic stitching → Full garment', style: TextStyle(fontSize: 11, color: AppColors.walnut, height: 1.5)),
                  SizedBox(height: 12),
                  Text('Start with Basics →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brick)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Text('🧵', style: TextStyle(fontSize: 48)),
          ],
        ),
      );
}

class _TutorialCard extends StatelessWidget {
  final _Tutorial tutorial;
  final VoidCallback onTap;
  const _TutorialCard({super.key, required this.tutorial, required this.onTap});

  Color get _levelColor => tutorial.level == 'Beginner' ? AppColors.terracotta : AppColors.walnut;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: AppColors.dustyRose,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(17)),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Text(tutorial.emoji, style: const TextStyle(fontSize: 40)),
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.9), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.brick),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tutorial.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.espresso), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(tutorial.description, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(8)),
                          child: Text(tutorial.level, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _levelColor)),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.access_time_rounded, size: 11, color: AppColors.iconMuted),
                        const SizedBox(width: 2),
                        Text(tutorial.duration, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        const Text('⭐', style: TextStyle(fontSize: 10)),
                        Text(' ${tutorial.rating}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(width: 6),
                        Text('${tutorial.views} views', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ]),
                    ],
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right_rounded, color: AppColors.dustyRose, size: 20)),
            ],
          ),
        ),
      );
}

class _QuickGuideGrid extends StatelessWidget {
  final _guides = [
    {'e': '📏', 'name': 'Taking\nMeasurements'},
    {'e': '✂️', 'name': 'Cutting\nBasics'},
    {'e': '🪡', 'name': 'Stitch\nTypes'},
    {'e': '🔧', 'name': 'Machine\nSetup'},
    {'e': '📌', 'name': 'Pinning\nTechniques'},
    {'e': '🧷', 'name': 'Finishing\nEdges'},
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.1),
          itemCount: _guides.length,
          itemBuilder: (_, i) => Container(
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_guides[i]['e']!, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(_guides[i]['name']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.espresso)),
              ],
            ),
          ),
        ),
      );
}
