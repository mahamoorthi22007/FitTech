import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'blueprint_screen.dart';




class AariScreen extends StatefulWidget {
  const AariScreen({super.key});
  @override
  State<AariScreen> createState() => _AariScreenState();
}

class _AariScreenState extends State<AariScreen> with TickerProviderStateMixin {
  int _tab = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() => _tab = _tabController.index));
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Aari & Embroidery'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.brick,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.brick,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Trending'), Tab(text: 'By Dress'), Tab(text: 'Tutorials')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_TrendingAari(), _ByDressAari(), _AariTutorials()],
      ),
    );
  }
}

class _TrendingAari extends StatelessWidget {
  final _patterns = [
    _AariPattern(emoji: '🌸', name: 'Rose Garden Border', style: 'Thread Aari', difficulty: 'Intermediate', desc: 'Delicate rose motifs along the hemline, popular for kurtis and blouses', trending: true),
    _AariPattern(emoji: '🦢', name: 'Swan Motif', style: 'Zari Work', difficulty: 'Advanced', desc: 'Traditional swan design for saree blouses and lehenga borders', trending: true),
    _AariPattern(emoji: '🌿', name: 'Creeper Vine', style: 'Thread Work', difficulty: 'Beginner', desc: 'Simple yet elegant vine pattern for everyday wear', trending: false),
    _AariPattern(emoji: '⭐', name: 'Star Cluster', style: 'Mirror Work', difficulty: 'Beginner', desc: 'Festive mirror embellishments for dupattas and blouses', trending: true),
    _AariPattern(emoji: '🦋', name: 'Butterfly Motif', style: 'Zardozi', difficulty: 'Advanced', desc: 'Intricate butterfly design with metallic thread for bridal wear', trending: false),
    _AariPattern(emoji: '🌺', name: 'Lotus Border', style: 'Aari Embroidery', difficulty: 'Intermediate', desc: 'Classic lotus pattern popular in South Indian bridal wear', trending: true),
  ];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('🔥 Trending This Season'),
            ..._patterns.where((p) => p.trending).map((p) => _AariCard(pattern: p)),
            const SectionLabel('All Patterns'),
            ..._patterns.where((p) => !p.trending).map((p) => _AariCard(pattern: p)),
            const SizedBox(height: 24),
          ],
        ),
      );
}

class _AariPattern {
  final String emoji, name, style, difficulty, desc;
  final bool trending;
  const _AariPattern({required this.emoji, required this.name, required this.style, required this.difficulty, required this.desc, required this.trending});
}

class _AariCard extends StatelessWidget {
  final _AariPattern pattern;
  const _AariCard({super.key, required this.pattern});

  Color get _diffColor => pattern.difficulty == 'Beginner' ? AppColors.terracotta : pattern.difficulty == 'Intermediate' ? AppColors.walnut : AppColors.brick;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pattern.trending ? AppColors.dustyRose : AppColors.divider, width: pattern.trending ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(pattern.emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(pattern.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.espresso))),
                    if (pattern.trending) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.dustyRose, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Hot 🔥', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.brick)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(pattern.style, style: const TextStyle(fontSize: 11, color: AppColors.terracotta, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(pattern.desc, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(8)),
                    child: Text(pattern.difficulty, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _diffColor)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ByDressAari extends StatefulWidget {
  @override
  State<_ByDressAari> createState() => _ByDressAariState();
}

class _ByDressAariState extends State<_ByDressAari> {
  final _dresses = ['Saree Blouse', 'Chudithar', 'Lehenga', 'Kurti', 'Shirt', 'Frock'];
  final _occasions = ['Bridal', 'Festival', 'Casual', 'Party', 'Wedding Guest'];
  final _fabrics = ['Silk', 'Cotton', 'Velvet', 'Organza', 'Georgette', 'Linen'];

  String _selDress = 'Saree Blouse';
  String _selOccasion = 'Bridal';
  String _selFabric = 'Silk';
  final _reqController = TextEditingController();

  bool _isLoading = false;
  List<dynamic> _recommendations = [];
  String? _errorMessage;

  @override
  void dispose() {
    _reqController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _recommendations = [];
    });

    try {
      final response = await http.post(
        Uri.parse('http://${BlueprintScreen.machineIp}:${BlueprintScreen.serverPort}/api/recommend-aari'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dressType': _selDress,
          'occasion': _selOccasion,
          'fabricType': _selFabric,
          'userRequirements': _reqController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['recommendations'] != null) {
          setState(() {
            _recommendations = data['recommendations'];
          });
        } else {
          setState(() {
            _errorMessage = "Invalid response from style engine.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server returned error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load recommendations: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. Select Outfit Configuration", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                  const SizedBox(height: 12),
                  _buildDropdown("Dress Type", _selDress, _dresses, (v) => setState(() => _selDress = v!)),
                  const SizedBox(height: 10),
                  _buildDropdown("Occasion", _selOccasion, _occasions, (v) => setState(() => _selOccasion = v!)),
                  const SizedBox(height: 10),
                  _buildDropdown("Fabric Material", _selFabric, _fabrics, (v) => setState(() => _selFabric = v!)),
                  const SizedBox(height: 16),
                  const Text("2. Describe Your Preferences / Motif", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reqController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "e.g., Mango motif along neck with heavy bead work, peacock design on back...",
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.iconMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brick,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _fetchRecommendations,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Generate AI Recommendations ✦", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
            ),
          if (_recommendations.isNotEmpty) ...[
            const SectionLabel('🌸 Recommended Aari Work'),
            ..._recommendations.map((r) => _AIRecommendedCard(rec: r)),
          ] else ...[
            const SectionLabel('Recommended Aari Work'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text("Select configurations above and click Generate to see tailor-made AI suggestions.", style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4)),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(fontSize: 13, color: AppColors.espresso, fontWeight: FontWeight.w600),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _AIRecommendedCard extends StatefulWidget {
  final Map<String, dynamic> rec;
  const _AIRecommendedCard({required this.rec});

  @override
  State<_AIRecommendedCard> createState() => _AIRecommendedCardState();
}

class _AIRecommendedCardState extends State<_AIRecommendedCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final difficulty = widget.rec['difficulty'] ?? 'Beginner';
    final diffColor = difficulty == 'Beginner' ? AppColors.terracotta : difficulty == 'Intermediate' ? AppColors.walnut : AppColors.brick;
    final materials = List<String>.from(widget.rec['materials'] ?? []);
    final instructions = widget.rec['instructions'] ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(widget.rec['emoji'] ?? '🌸', style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.rec['name'] ?? 'Custom Design', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.espresso)),
                    const SizedBox(height: 2),
                    Text(widget.rec['style'] ?? 'Embroidery', style: const TextStyle(fontSize: 11, color: AppColors.terracotta, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(8)),
                child: Text(difficulty, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: diffColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.rec['desc'] ?? '', style: const TextStyle(fontSize: 11.5, color: AppColors.espresso, height: 1.45)),
          if (materials.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text("Materials Needed:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brick)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: materials.map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(6)),
                child: Text(m, style: const TextStyle(fontSize: 10, color: AppColors.espresso)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_expanded ? "Hide Tracing & Stitching Guide" : "View Tracing & Stitching Guide", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.brick)),
                Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: AppColors.brick),
              ],
            ),
          ),
          if (_expanded && instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(instructions, style: const TextStyle(fontSize: 11.5, color: AppColors.walnut, height: 1.45)),
          ],
        ],
      ),
    );
  }
}

class _AariTutorials extends StatelessWidget {
  final _tutorials = [
    {'e': '🪡', 'title': 'Introduction to Aari Needle', 'dur': '18 min', 'level': 'Beginner'},
    {'e': '🌸', 'title': 'Basic Floral Stitch Patterns', 'dur': '32 min', 'level': 'Beginner'},
    {'e': '🌿', 'title': 'Vine & Creeper Embroidery', 'dur': '45 min', 'level': 'Intermediate'},
    {'e': '🦢', 'title': 'Traditional Motif Designs', 'dur': '1h 10m', 'level': 'Intermediate'},
    {'e': '💎', 'title': 'Zardozi & Metallic Thread', 'dur': '1h 30m', 'level': 'Advanced'},
  ];

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        itemCount: _tutorials.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final t = _tutorials[i];
          return Container(
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
            child: Row(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.dustyRose,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Text(t['e']!, style: const TextStyle(fontSize: 32)),
                  Positioned(bottom: 8, right: 8, child: Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, size: 14, color: AppColors.brick),
                  )),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.espresso), maxLines: 2),
                const SizedBox(height: 6),
                Row(children: [
                  _TutTag(t['level']!),
                  const SizedBox(width: 6),
                  Text('⏱ ${t['dur']}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ]),
              ])),
              const Padding(padding: EdgeInsets.only(right: 14), child: Icon(Icons.chevron_right_rounded, color: AppColors.dustyRose)),
            ]),
          );
        },
      );
}

class _TutTag extends StatelessWidget {
  final String label;
  const _TutTag(this.label);
  Color get _color => label == 'Beginner' ? AppColors.terracotta : label == 'Intermediate' ? AppColors.walnut : AppColors.brick;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _color)),
      );
}
