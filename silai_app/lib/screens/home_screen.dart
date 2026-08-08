import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'trending_screen.dart';
import 'recommend_screen.dart';
import 'blueprint_screen.dart' hide SectionLabel, PrimaryButton; 
import 'tutorial_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'aari_screen.dart'; // உங்கள் கோப்பு இருக்கும் இடத்திற்கு ஏற்ப மாற்றவும்

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _carouselTimer;
  bool _isLoading = false;

  File? _userImage;
  final ImagePicker _picker = ImagePicker();

  // Updated array mapping your 4 home asset files dynamically
  final List<String> _bannerImages = [
    'assets/images/home1.png',
    'assets/images/home2.png',
    'assets/images/home3.png',
    'assets/images/home4.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _bannerImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Dynamic navigator that correctly pushes the exact screen widget passed to it
  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _pickImageAndRecommend() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _userImage = File(pickedFile.path);
        _isLoading = true;
      });

      List<int> imageBytes = await _userImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      try {
        final response = await http.post(
          Uri.parse('http://${BlueprintScreen.machineIp}:${BlueprintScreen.serverPort}/api/recommend-style'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "image": base64Image,
          }),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // CRITICAL FIXED PIPELINE LINK: Passes the user uploaded base64 data directly 
          // forward to pre-populate Step 1 of the Blueprint Studio workspace!
          if (mounted) {
            _navigate(
              context, 
              BlueprintScreen(
                dressType: data['recommended_type'] ?? "AI Recommended Style",
                passedDesignImage: base64Image,
              ),
            );
          }
        } else {
          throw Exception("Server responded with code ${response.statusCode}");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching recommendation: $e")));
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  Future<void> _generateAvatarVideoLesson(String garmentName) async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.post(
        Uri.parse('http://${BlueprintScreen.machineIp}:${BlueprintScreen.serverPort}/api/generate-video-lesson'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "garmentType": garmentName,
          "languagePreference": "English"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Success! HeyGen Video Queued. Session ID: ${data['heygenSessionId']}")),
          );
        }
      } else {
        throw Exception("Server responded with code ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Video engine error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const SilaiAppBar(),
      body: Stack(
        children: [
          // Primary content layer
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Re-architected Home Carousel viewport wrapper
                  SizedBox(
                    height: 220, 
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemCount: _bannerImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.dustyRose,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              key: ValueKey('carousel_slide_$index'),
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    _bannerImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withAlpha(165),
                                          Colors.black.withAlpha(38),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  bottom: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.terracotta,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          '✦ AI SILAI STUDIO', 
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Stitch Your Dream Outfit',
                                        style: TextStyle(
                                          fontFamily: 'Playfair Display',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // 2. Active Dot Navigation Layout Panel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _bannerImages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.brick : AppColors.divider,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // 2b. NEW: User Engagement Dashboard
                  _buildUserDashboard(),

                  // 2c. NEW: Today's Challenge Section
                  _buildTodayChallenge(),

                  const SectionLabel('✦ Quick Access'),
                  _QuickAccessRow(
                    onTapBlueprint: () => _navigate(context, const BlueprintScreen(dressType: "Standard Churidar")),
                    onTapStylist: _pickImageAndRecommend,
                    onTapTrending: () => _navigate(context, const TrendingScreen()),
                    onTapTutorials: () => _navigate(context, const TutorialScreen()),
                  ),
                  
                  const SectionLabel('✦ Explore Features'),
                  FeatureRowCard(
                    emoji: '🪞',
                    title: 'Style Recommender',
                    subtitle: 'Upload your photo → get personalised outfit suggestions',
                    aiTag: true,
                    onTap: _pickImageAndRecommend,
                  ),
                  FeatureRowCard(
                    emoji: '👕',
                    title: 'AI Try-On',
                    subtitle: 'Upload your photo and a dress photo to see how it fits',
                    aiTag: true,
                    onTap: () => _navigate(
                      context,
                      const BlueprintScreen(
                        dressType: "Try-On",
                        initialStep: 3,
                      ),
                    ),
                  ),
                  FeatureRowCard(
                    emoji: '📐',
                    title: 'Blueprint Studio',
                    subtitle: 'Enter measurements → get a shareable stitching blueprint',
                    aiTag: true,
                    onTap: () => _navigate(context, const BlueprintScreen(dressType: "Custom Design")),
                  ),
                  FeatureRowCard(
                    emoji: '🎬',
                    title: 'Generate AI Avatar Lesson',
                    subtitle: 'Create interactive video masterclass with HeyGen',
                    aiTag: true,
                    onTap: () => _generateAvatarVideoLesson("Designer Chudithar"),
                  ),
                  FeatureRowCard(
                    emoji: '🔥',
                    title: 'Trending Designs',
                    subtitle: 'Seasonal picks for all genders & age groups',
                    onTap: () => _navigate(context, const TrendingScreen()),
                  ),
                  FeatureRowCard(
                    emoji: '🎓',
                    title: 'Learn Tailoring',
                    subtitle: 'Step-by-step tutorials from beginner to expert',
                    onTap: () => _navigate(context, const TutorialScreen()),
                  ),
                  
                  const SectionLabel('✦ Fabric Spotlight'),
                  const _FabricSpotlight(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // 3. Loading Overlay Layer Frame
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.terracotta),
                          SizedBox(height: 16),
                          Text("Processing Engine Request...", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper widget for User Stats (as per WhatsApp Image 2026-06-13 at 8.07.21 AM.jpeg)
  Widget _buildUserDashboard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Good Morning, Maha ☀️", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("Ready to create something beautiful?"),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _statItem(Icons.star_border, "Level 12"),
                    _statItem(Icons.emoji_events, "2,450 XP"),
                    _statItem(Icons.local_fire_department, "7 Day"),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.dry_cleaning, size: 60, color: AppColors.dustyRose),
        ],
      ),
    );
  }

  // Helper widget for Challenge Card (as per WhatsApp Image 2026-06-13 at 8.07.21 AM.jpeg)
  Widget _buildTodayChallenge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TODAY'S CHALLENGE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const Text("Draft a Puff Sleeve Pattern", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {}, 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brick),
            child: const Text("Start Challenge →", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Row(children: [Icon(icon, size: 16), Text(" $text", style: const TextStyle(fontWeight: FontWeight.w600))]),
  );
}

// Quick Access row: 4 tappable shortcut tiles (Blueprint, Stylist, Trending, Tutorials)
class _QuickAccessRow extends StatelessWidget {
  final VoidCallback onTapBlueprint;
  final VoidCallback onTapStylist;
  final VoidCallback onTapTrending;
  final VoidCallback onTapTutorials;

  const _QuickAccessRow({
    required this.onTapBlueprint,
    required this.onTapStylist,
    required this.onTapTrending,
    required this.onTapTutorials,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _QuickAccessTile(
              icon: Icons.straighten,
              label: 'Blueprint',
              color: AppColors.terracotta,
              onTap: onTapBlueprint,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAccessTile(
              icon: Icons.auto_awesome,
              label: 'Stylist',
              color: AppColors.dustyRose,
              onTap: onTapStylist,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAccessTile(
              icon: Icons.local_fire_department,
              label: 'Trending',
              color: AppColors.brick,
              onTap: onTapTrending,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAccessTile(
              icon: Icons.school,
              label: 'Tutorials',
              color: AppColors.blushLight,
              onTap: onTapTutorials,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fabric Spotlight ─────────────────────────────────────────────────────────
// Placeholder horizontal showcase of fabric types. Static sample data for now —
// swap _fabrics for a PexelsService.fetchCategory('fabric') call later to pull
// in live photos instead of color swatches.
class _FabricSpotlight extends StatelessWidget {
  const _FabricSpotlight();

  static const List<Map<String, Object>> _fabrics = [
    {'emoji': '🌿', 'name': 'Cotton', 'note': 'Breathable, daily wear', 'color': AppColors.blushLight},
    {'emoji': '✨', 'name': 'Silk', 'note': 'Elegant, occasions', 'color': AppColors.dustyRose},
    {'emoji': '💎', 'name': 'Georgette', 'note': 'Flowy, semi-formal', 'color': AppColors.divider},
    {'emoji': '🌸', 'name': 'Chanderi', 'note': 'Lightweight, festive', 'color': AppColors.blushLight},
    {'emoji': '🍃', 'name': 'Linen', 'note': 'Natural, summer', 'color': AppColors.dustyRose},
    {'emoji': '🌺', 'name': 'Organza', 'note': 'Sheer, bridal', 'color': AppColors.divider},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: _fabrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final f = _fabrics[index];
          return _FabricCard(
            emoji: f['emoji'] as String,
            name: f['name'] as String,
            note: f['note'] as String,
            swatchColor: f['color'] as Color,
          );
        },
      ),
    );
  }
}

class _FabricCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String note;
  final Color swatchColor;

  const _FabricCard({
    required this.emoji,
    required this.name,
    required this.note,
    required this.swatchColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: swatchColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.espresso),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}