import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'blueprint_screen.dart' hide SectionLabel, PrimaryButton;

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  int _genderFilter = 0; // 0: All, 1: Female, 2: Male, 3: Kids
  int _categoryFilter = 0;

  late final PageController _trendingPageController;
  int _trendingCurrentPage = 0;
  Timer? _trendingTimer;

  final _genderFilters = ['All', 'Female', 'Male', 'Kids'];
  final _categoryFilters = ['All', 'Traditional', 'Western', 'Casual', 'Festive'];

  // 🎭 GENDER SPECIFIC THEMES (Background & Accent Colors)
  Color _getThemeBgColor() {
    switch (_genderFilter) {
      case 1: return const Color(0xFFFFF0F5); // Soft Rose Velvet
      case 2: return const Color(0xFFF0F4F8); // Slate Male Blue
      case 3: return const Color(0xFFFFF9E6); // Playful Kids Yellow
      default: return AppColors.cream;
    }
  }

  Color _getThemeAccentColor() {
    switch (_genderFilter) {
      case 1: return AppColors.terracotta;
      case 2: return const Color(0xFF2B4C7E); // Classic Navy
      case 3: return Colors.orangeAccent;
      default: return AppColors.espresso;
    }
  }

  // 🎠 DYNAMIC CAROUSEL DATA (4 Real Images Per Gender Category)
  List<Map<String, String>> _getCarouselItems() {
    switch (_genderFilter) {
      case 1: // Female
        return [
          {'image': 'assets/images/b2.jpg', 'title': 'Bridal Zari Work', 'sub': 'Premium Handcrafted Blouses'},
          {'image': 'assets/images/c1.jpg', 'title': 'Cotton Anarkali Suits', 'sub': 'Elegant Festive Looks'},
          {'image': 'assets/images/b1.jpg', 'title': 'Aari Work Magic', 'sub': 'Trending Designer Series'},
          {'image': 'assets/images/c2.jpg', 'title': 'Flared Georgette Kurtis', 'sub': 'Modern Ethnic Vibe'},
        ];
      case 2: // Male
        return [
          {'image': 'assets/images/m2.jpg', 'title': 'Royal Silk Kurta Set', 'sub': 'Traditional Wedding Attire'},
          {'image': 'assets/images/m3.jpg', 'title': 'Premium Jodhpur Suit', 'sub': 'Modern Tailored Fit'},
          {'image': 'assets/images/m1.jpg', 'title': 'Linen Formal Comfort', 'sub': 'Minimalist Casual Wear'},
          {'image': 'assets/images/m4.jpg', 'title': 'Nehru Jacket Outfits', 'sub': 'Classic Festive Standard'},
        ];
      case 3: // Kids
        return [
          {'image': 'assets/images/bc3.jpg', 'title': 'Traditional Pattu Pavadai', 'sub': 'Heritage Wear for Kids'},
          {'image': 'assets/images/bc4.jpg', 'title': 'Birthday Special Suits', 'sub': 'Adorable Little Outfits'},
          {'image': 'assets/images/bc1.jpg', 'title': 'Formal Kids Blazer Set', 'sub': 'Gentleman Look'},
          {'image': 'assets/images/bc2.jpg', 'title': 'Organic Cotton Frocks', 'sub': 'Daily Comfort Guaranteed'},
        ];
      default: // All
        return [
          {'image': 'assets/images/b2.jpg', 'title': 'Handmade Bridal Masterpiece', 'sub': 'Exclusive Design Hub'},
          {'image': 'assets/images/m2.jpg', 'title': 'Premium Men Ethnic Kurta', 'sub': 'Festive Splendor'},
          {'image': 'assets/images/bc3.jpg', 'title': 'Bright Pattu Pavadai Collection', 'sub': 'Pure Southern Grace'},
          {'image': 'assets/images/c1.jpg', 'title': 'Designer Indigo Salwar', 'sub': 'Everyday Elegance'},
        ];
    }
  }

  final List<Map<String, String>> _genderFilterData = [
    {'name': 'All', 'image': 'assets/images/c1.jpg'},
    {'name': 'Female', 'image': 'assets/images/b1.jpg'},
    {'name': 'Male', 'image': 'assets/images/m2.jpg'},
    {'name': 'Kids', 'image': 'assets/images/bc4.jpg'},
  ];

  final List<Map<String, String>> _categoryFilterData = [
    {'name': 'All', 'image': 'assets/images/c12.jpg'},
    {'name': 'Traditional', 'image': 'assets/images/b2.jpg'},
    {'name': 'Western', 'image': 'assets/images/m3.jpg'},
    {'name': 'Casual', 'image': 'assets/images/c11.jpg'},
    {'name': 'Festive', 'image': 'assets/images/bc3.jpg'},
  ];

  final List<_TrendItem> _allTrends = [
    _TrendItem(imagePath: 'assets/images/c1.jpg', name: 'Premium Cotton Chudithar', tag: 'Female', style: 'Traditional', badge: '🔥 Hot'),
    _TrendItem(imagePath: 'assets/images/c2.jpg', name: 'Designer Anarkali Suit', tag: 'Female', style: 'Traditional', badge: '↑ Rising'),
    _TrendItem(imagePath: 'assets/images/c11.jpg', name: 'Floral Summer Kurti', tag: 'Female', style: 'Casual', badge: '✦ New'),
    _TrendItem(imagePath: 'assets/images/c12.jpg', name: 'Elegant Daily Wear Kurti', tag: 'Female', style: 'Casual', badge: 'Classic'),
    _TrendItem(imagePath: 'assets/images/b1.jpg', name: 'Hand Embroidery Aari Blouse', tag: 'Female', style: 'Traditional', badge: '🔥 Hot'),
    _TrendItem(imagePath: 'assets/images/b2.jpg', name: 'Grand Bridal Designer Blouse', tag: 'Female', style: 'Festive', badge: '👑 Best'),
    _TrendItem(imagePath: 'assets/images/b3.jpg', name: 'Stylish Boat Neck Pattern', tag: 'Female', style: 'Western', badge: '↑ Rising'),
    _TrendItem(imagePath: 'assets/images/m1.jpg', name: 'Pure Linen Premium Shirt', tag: 'Male', style: 'Casual', badge: '✦ New'),
    _TrendItem(imagePath: 'assets/images/m2.jpg', name: 'Ethnic Wedding Kurta', tag: 'Male', style: 'Traditional', badge: '🔥 Hot'),
    _TrendItem(imagePath: 'assets/images/m3.jpg', name: 'Luxury Jodhpur Suit', tag: 'Male', style: 'Festive', badge: 'Elegant'),
    _TrendItem(imagePath: 'assets/images/m4.jpg', name: 'Royal Nehru Jacket Combo', tag: 'Male', style: 'Traditional', badge: 'Trending'),
    _TrendItem(imagePath: 'assets/images/m5.jpg', name: 'Classic Formal Collar Shirt', tag: 'Male', style: 'Casual', badge: 'Office'),
    _TrendItem(imagePath: 'assets/images/m6.jpg', name: 'Indo-Western Party Kurta', tag: 'Male', style: 'Western', badge: '✦ New'),
    _TrendItem(imagePath: 'assets/images/m7.jpg', name: 'Casual Slim Fit Tunic', tag: 'Male', style: 'Casual', badge: 'Comfy'),
    _TrendItem(imagePath: 'assets/images/m8.jpg', name: 'Traditional Sherwani Set', tag: 'Male', style: 'Festive', badge: 'Royal'),
    _TrendItem(imagePath: 'assets/images/bc1.jpg', name: 'Gentleman Formal Boy Suit', tag: 'Kids', style: 'Western', badge: 'Cute'),
    _TrendItem(imagePath: 'assets/images/bc2.jpg', name: 'Infant Organic Cotton Frock', tag: 'Kids', style: 'Casual', badge: '✦ New'),
    _TrendItem(imagePath: 'assets/images/bc3.jpg', name: 'South Traditional Pattu Pavadai', tag: 'Kids', style: 'Traditional', badge: 'Festive'),
    _TrendItem(imagePath: 'assets/images/bc4.jpg', name: 'Kids Birthday Special Suit', tag: 'Kids', style: 'Festive', badge: '👑 Best'),
    _TrendItem(imagePath: 'assets/images/bc5.jpg', name: 'Summer Multi-color Romper', tag: 'Kids', style: 'Casual', badge: 'Trending'),
    _TrendItem(imagePath: 'assets/images/bc6.jpg', name: 'Cute Designer Baba Suit', tag: 'Kids', style: 'Casual', badge: '✦ New'),
    _TrendItem(imagePath: 'assets/images/bc7.jpg', name: 'Kids Party Wear Indo-Western', tag: 'Kids', style: 'Western', badge: 'Charming'),
    _TrendItem(imagePath: 'assets/images/bc8.jpg', name: 'Festive Silk Dhoti Kurta Set', tag: 'Kids', style: 'Traditional', badge: 'Classic'),
    _TrendItem(imagePath: 'assets/images/bc9.jpg', name: 'Printed Holiday Beach Outfit', tag: 'Kids', style: 'Western', badge: 'Vacay'),
  ];

  List<_TrendItem> get _filtered {
    final g = _genderFilters[_genderFilter];
    final c = _categoryFilters[_categoryFilter];
    return _allTrends.where((t) {
      final gMatch = g == 'All' || t.tag == g;
      final cMatch = c == 'All' || t.style == c;
      return gMatch && cMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _trendingPageController = PageController(initialPage: 0);
    _startCarouselTimer();
  }

  void _startCarouselTimer() {
    _trendingTimer?.cancel();
    _trendingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_trendingCurrentPage < 3) {
        _trendingCurrentPage++;
      } else {
        _trendingCurrentPage = 0;
      }
      if (_trendingPageController.hasClients) {
        _trendingPageController.animateToPage(
          _trendingCurrentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _trendingTimer?.cancel();
    _trendingPageController.dispose();
    super.dispose();
  }

  void _showTryOutfitDialog(BuildContext context, _TrendItem item) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.white,
          title: Text('Try This Design? 🪡', style: TextStyle(fontFamily: 'Playfair Display', color: _getThemeAccentColor(), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(item.imagePath, height: 160, fit: BoxFit.cover),
              ),
              const SizedBox(height: 14),
              Text('Do you want to try "${item.name}" and generate your stitching blueprint?', style: const TextStyle(fontSize: 13, color: AppColors.espresso, height: 1.4)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _getThemeAccentColor(), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Navigator.pop(ctx); 
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlueprintScreen(
                      dressType: item.name,
                      skipToMeasurements: true,
                      passedDesignAsset: item.imagePath,
                    ),
                  ),
                );
              },
              child: const Text('Yes, Let\'s Stitch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final carouselItems = _getCarouselItems();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: _getThemeBgColor(),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: const SilaiAppBar(),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trending Now ✦', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                        SizedBox(height: 4),
                        Text('Curated seasonal picks • Updated weekly', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),

                  // ─── BIG AUTOPLAY TRENDING CAROUSEL ───
                  SizedBox(
                    height: 320, 
                    child: PageView.builder(
                      controller: _trendingPageController,
                      itemCount: carouselItems.length,
                      onPageChanged: (val) => setState(() => _trendingCurrentPage = val),
                      itemBuilder: (context, idx) {
                        final currentItem = carouselItems[idx];
                        return _buildCarouselCard(currentItem['image']!, currentItem['title']!, currentItem['sub']!);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  SectionLabel('Gender Selection'),
                  SizedBox(
                    height: 105,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: _genderFilterData.length,
                      itemBuilder: (context, index) {
                        final isSelected = _genderFilter == index;
                        final data = _genderFilterData[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _genderFilter = index;
                              _trendingCurrentPage = 0;
                              _trendingPageController.jumpToPage(0);
                              _startCarouselTimer(); 
                            });
                          },
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? _getThemeAccentColor() : AppColors.divider, width: isSelected ? 3.5 : 1.5),
                                  boxShadow: isSelected ? [BoxShadow(color: _getThemeAccentColor().withOpacity(0.3), blurRadius: 10, spreadRadius: 1)] : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(34),
                                  child: Image.asset(data['image']!, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(data['name']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? _getThemeAccentColor() : AppColors.espresso)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  SectionLabel('Style Categories'),
                  SizedBox(
                    height: 105,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: _categoryFilterData.length,
                      itemBuilder: (context, index) {
                        final isSelected = _categoryFilter == index;
                        final data = _categoryFilterData[index];
                        return GestureDetector(
                          onTap: () => setState(() => _categoryFilter = index),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? _getThemeAccentColor() : AppColors.divider, width: isSelected ? 3.5 : 1.5),
                                  boxShadow: isSelected ? [BoxShadow(color: _getThemeAccentColor().withOpacity(0.2), blurRadius: 8)] : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(34),
                                  child: Image.asset(data['image']!, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(data['name']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? _getThemeAccentColor() : AppColors.textMuted)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  SectionLabel('🔥 Live Pinterest Catalog'),
                ],
              ),
            ),

            // ─── PINTEREST STYLE MASONRY GRID (FIXED FOR VERSION 0.7.0) ───
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: filtered.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('No designs found in this category!', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      ),
                    )
                  : SliverMasonryGrid(
                      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          return _PinterestCard(
                            item: filtered[i],
                            accentColor: _getThemeAccentColor(),
                            onCardTap: () => _showTryOutfitDialog(context, filtered[i]),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselCard(String imgPath, String title, String sub) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(imgPath, fit: BoxFit.cover)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _getThemeAccentColor(), borderRadius: BorderRadius.circular(12)),
                    child: const Text('SPOTLIGHT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display')),
                  const SizedBox(height: 4),
                  Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendItem {
  final String imagePath, name, tag, style, badge;
  const _TrendItem({required this.imagePath, required this.name, required this.tag, required this.style, required this.badge});
}

class _PinterestCard extends StatefulWidget {
  final _TrendItem item;
  final Color accentColor;
  final VoidCallback onCardTap;

  const _PinterestCard({required this.item, required this.accentColor, required this.onCardTap});

  @override
  State<_PinterestCard> createState() => _PinterestCardState();
}

class _PinterestCardState extends State<_PinterestCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: widget.onCardTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: _isHovered ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _isHovered ? widget.accentColor.withOpacity(0.5) : AppColors.divider, width: _isHovered ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? widget.accentColor.withOpacity(0.12) : Colors.black.withOpacity(0.02),
                blurRadius: _isHovered ? 12 : 6,
                offset: _isHovered ? const Offset(0, 6) : const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                    child: AnimatedScale(
                      scale: _isHovered ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(widget.item.imagePath, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(10)),
                      child: Text(widget.item.tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: widget.accentColor)),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: widget.accentColor.withOpacity(0.85), borderRadius: BorderRadius.circular(8)),
                      child: Text(widget.item.badge, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name, 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso, height: 1.3), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.item.style, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        if (_isHovered)
                          Icon(Icons.arrow_forward_ios, size: 10, color: widget.accentColor)
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}