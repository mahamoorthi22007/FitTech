import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Universal auto-scrolling carousel — same size on every screen
class SilaiCarousel extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final double itemWidth;
  final bool autoScroll;
  final Duration autoScrollInterval;

  const SilaiCarousel({
    super.key,
    required this.items,
    this.height = 200,
    this.itemWidth = 280,
    this.autoScroll = true,
    this.autoScrollInterval = const Duration(seconds: 3),
  });

  @override
  State<SilaiCarousel> createState() => _SilaiCarouselState();
}

class _SilaiCarouselState extends State<SilaiCarousel> {
  late PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88, initialPage: 0);
    if (widget.autoScroll && widget.items.length > 1) {
      Future.delayed(widget.autoScrollInterval, _autoAdvance);
    }
  }

  void _autoAdvance() {
    if (!mounted) return;
    final next = (_current + 1) % widget.items.length;
    _controller.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    Future.delayed(widget.autoScrollInterval, _autoAdvance);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.items.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: widget.items[i],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Dots(count: widget.items.length, current: _current),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count, current;
  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: i == current ? 18 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: i == current ? AppColors.brick : AppColors.dustyRose,
            borderRadius: BorderRadius.circular(3),
          ),
        )),
      );
}

/// A banner slide for the hero carousel
class HeroBannerSlide extends StatelessWidget {
  final String emoji;
  final String tag;
  final String title;
  final String subtitle;
  final Color bgColor;
  final VoidCallback? onTap;

  const HeroBannerSlide({
    super.key,
    required this.emoji,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              // Decor circle
              Positioned(
                top: -20, right: -20,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -10, left: -10,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6)),
                          ),
                          const SizedBox(height: 10),
                          Text(title, style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.25,
                          )),
                          const SizedBox(height: 6),
                          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85), height: 1.45)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(emoji, style: const TextStyle(fontSize: 58)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Image card with "Try This?" tap
class PexelsImageCard extends StatefulWidget {
  final String imageUrl;
  final String label;
  final VoidCallback? onTryThis;
  final double borderRadius;

  const PexelsImageCard({
    super.key,
    required this.imageUrl,
    required this.label,
    this.onTryThis,
    this.borderRadius = 16,
  });

  @override
  State<PexelsImageCard> createState() => _PexelsImageCardState();
}

class _PexelsImageCardState extends State<PexelsImageCard> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        color: AppColors.blushLight,
                        child: const Center(child: CircularProgressIndicator(color: AppColors.terracotta, strokeWidth: 2)),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.blushLight,
                  child: const Center(child: Text('🪡', style: TextStyle(fontSize: 36))),
                ),
              ),

              // Gradient bottom
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                    ),
                  ),
                ),
              ),

              // Label
              Positioned(
                bottom: 10, left: 10,
                child: Text(widget.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ),

              // "Try This?" overlay
              AnimatedOpacity(
                opacity: _showOverlay ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: AppColors.espresso.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✦', style: TextStyle(fontSize: 22, color: AppColors.dustyRose)),
                        const SizedBox(height: 6),
                        const Text('Try This?', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () { setState(() => _showOverlay = false); widget.onTryThis?.call(); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(color: AppColors.brick, borderRadius: BorderRadius.circular(22)),
                                child: const Text('Yes!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setState(() => _showOverlay = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white54),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Text('No', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
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
          ),
        ),
      );
}
