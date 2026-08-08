import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'blueprint_screen.dart' hide SectionLabel, PrimaryButton;

class RecommendScreen extends StatefulWidget {
  final dynamic recommendationData; // Added property to hold API response

  const RecommendScreen({super.key, this.recommendationData});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  late String _selectedDress;
  late String _selectedGender;
  late String _selectedStyle;
  late String _selectedNeck;
  late String _selectedSleeve;

  final _genders = ['Female', 'Male', 'Kids'];
  final _dressOptions = {
    'Female': ['Chudithar', 'Saree Blouse', 'Anarkali', 'Kurti', 'Lehenga', 'Frock', 'Skirt'],
    'Male': ['Shirt', 'Trousers', 'Kurta', 'Bandhgala', 'Dhoti', 'Pant'],
    'Kids': ['Frock', 'Pattu Pavadai', 'Shirt', 'Shorts', 'Skirt'],
  };

  final _chuditharStyles = ['Straight Cut', 'Anarkali Style', 'Sharara Set', 'Jacket Style', 'Asymmetric', 'Flared'];
  final _neckDesigns = ['Round Neck', 'V-Neck', 'Boat Neck', 'High Neck', 'Square Neck', 'Keyhole'];
  final _sleeveStyles = ['Full Sleeve', 'Bell Sleeve', 'Puff Sleeve', 'Sleeveless', 'Cap Sleeve', '3/4 Sleeve'];
  final _shirtStyles = ['Regular Fit', 'Slim Fit', 'Oversized', 'Mandarin Collar', 'Classic'];
  final _pantStyles = ['Straight', 'Bootcut', 'Slim Fit', 'Palazzo', 'Churidar'];

  @override
  void initState() {
    super.initState();
    _initializeSelections();
  }

  /// Parses incoming hook data or initializes to clean defaults if empty
  void _initializeSelections() {
    final data = widget.recommendationData;

    if (data != null && data is Map<String, dynamic>) {
      // Extract properties using backend response structure safely
      _selectedGender = data['gender'] ?? 'Female';
      _selectedDress = data['garmentType'] ?? (_dressOptions[_selectedGender]?.first ?? 'Chudithar');
      _selectedStyle = data['styleVariant'] ?? '';
      _selectedNeck = data['neckDesign'] ?? '';
      _selectedSleeve = data['sleeveStyle'] ?? '';
    } else {
      // Fallback defaults if arrived via manual tap configuration
      _selectedGender = 'Female';
      _selectedDress = 'Chudithar';
      _selectedStyle = '';
      _selectedNeck = '';
      _selectedSleeve = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dresses = _dressOptions[_selectedGender] ?? [];
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('AI Style Recommender'),
        leading: const BackButton(color: AppColors.brick),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 2),
              child: const Text(
                'Tell us about your fabric,\nwe\'ll suggest the perfect outfit', 
                style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.espresso, height: 1.3),
              ),
            ),
            const SizedBox(height: 14),
            UploadZone(emoji: '🪢', title: 'Upload Your Fabric', subtitle: 'Or describe the material & colour', buttonText: 'Upload Fabric Photo'),
            const SectionLabel('Select Gender'),
            _GenderSelector(
              selected: _selectedGender,
              options: _genders,
              onChanged: (v) => setState(() { 
                _selectedGender = v; 
                _selectedDress = _dressOptions[v]!.first; 
                _selectedStyle = '';
                _selectedNeck = '';
                _selectedSleeve = '';
              }),
            ),
            const SectionLabel('I Want to Make'),
            SelectablePillRow(
              items: dresses,
              // Match manual selections if user changes choices post-API prediction
              onSelected: (v) => setState(() {
                _selectedDress = v;
                _selectedStyle = '';
                _selectedNeck = '';
                _selectedSleeve = '';
              }),
            ),
            const SizedBox(height: 14),

            // ─ Conditional styling layout selections ─
            if (_selectedDress == 'Chudithar' || _selectedDress == 'Anarkali' || _selectedDress == 'Kurti') ...[
              const SectionLabel('✦ Style Variant'),
              _ScrollSelectRow(items: _chuditharStyles, onSelected: (v) => setState(() => _selectedStyle = v)),
              const SectionLabel('✦ Neck Design'),
              _NeckDesignRow(items: _neckDesigns, onSelected: (v) => setState(() => _selectedNeck = v)),
              const SectionLabel('✦ Sleeve Style'),
              _SleeveRow(items: _sleeveStyles, onSelected: (v) => setState(() => _selectedSleeve = v)),
            ],
            if (_selectedDress == 'Shirt' || _selectedDress == 'Kurta') ...[
              const SectionLabel('✦ Collar & Style'),
              _ScrollSelectRow(items: _shirtStyles, onSelected: (v) => setState(() => _selectedStyle = v)),
              const SectionLabel('✦ Sleeve'),
              _SleeveRow(items: ['Full Sleeve', '3/4 Sleeve', 'Half Sleeve', 'Sleeveless'], onSelected: (v) => setState(() => _selectedSleeve = v)),
            ],
            if (_selectedDress == 'Trousers' || _selectedDress == 'Pant') ...[
              const SectionLabel('✦ Trouser Style'),
              _ScrollSelectRow(items: _pantStyles, onSelected: (v) => setState(() => _selectedStyle = v)),
            ],
            if (_selectedDress == 'Saree Blouse') ...[
              const SectionLabel('✦ Back Design'),
              _ScrollSelectRow(items: ['Plain Back', 'Deep Back', 'Bow Back', 'Criss-cross', 'Sheer Panel'], onSelected: (v) => setState(() => _selectedStyle = v)),
              const SectionLabel('✦ Neck Design'),
              _NeckDesignRow(items: _neckDesigns, onSelected: (v) => setState(() => _selectedNeck = v)),
            ],
            if (_selectedDress == 'Lehenga') ...[
              const SectionLabel('✦ Lehenga Style'),
              _ScrollSelectRow(items: ['A-line', 'Fishtail', 'Layered', 'Straight', 'Circular'], onSelected: (v) => setState(() => _selectedStyle = v)),
              const SectionLabel('✦ Blouse Style'),
              _NeckDesignRow(items: ['Halter Neck', 'Off-shoulder', 'Full Sleeve', 'Corset', 'Backless'], onSelected: (v) => setState(() => _selectedNeck = v)),
            ],
            
            const SectionLabel('🪡 AI Fabric Recommendation'),
            _FabricSuggestionCard(dressType: _selectedDress),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Generate Blueprint for $_selectedDress →',
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => BlueprintScreen(dressType: _selectedDress)
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _GenderSelector({required this.selected, required this.options, required this.onChanged});

  final _icons = const {'Female': '👩', 'Male': '👨', 'Kids': '🧒'};

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: options.map((o) {
            final active = o == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.brick : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? AppColors.brick : AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Text(_icons[o] ?? '👤', style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(o, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? AppColors.white : AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _ScrollSelectRow extends StatefulWidget {
  final List<String> items;
  final ValueChanged<String> onSelected;
  const _ScrollSelectRow({required this.items, required this.onSelected});
  @override
  State<_ScrollSelectRow> createState() => _ScrollSelectRowState();
}

class _ScrollSelectRowState extends State<_ScrollSelectRow> {
  int _sel = 0;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: widget.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == _sel;
            return GestureDetector(
              onTap: () { setState(() => _sel = i); widget.onSelected(widget.items[i]); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.dustyRose : AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: active ? AppColors.terracotta : AppColors.divider),
                ),
                child: Text(widget.items[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? AppColors.brick : AppColors.textMuted)),
              ),
            );
          },
        ),
      );
}

class _NeckDesignRow extends StatefulWidget {
  final List<String> items;
  final ValueChanged<String> onSelected;
  const _NeckDesignRow({required this.items, required this.onSelected});
  @override
  State<_NeckDesignRow> createState() => _NeckDesignRowState();
}

class _NeckDesignRowState extends State<_NeckDesignRow> {
  int _sel = 0;
  final _neckEmojis = {'Round Neck': '⭕', 'V-Neck': '✌️', 'Boat Neck': '🚢', 'High Neck': '🔝', 'Square Neck': '⬛', 'Keyhole': '🔑', 'Halter Neck': '🪢', 'Off-shoulder': '💫', 'Full Sleeve': '💪', 'Corset': '👗', 'Backless': '🌸'};

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: widget.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == _sel;
            return GestureDetector(
              onTap: () { setState(() => _sel = i); widget.onSelected(widget.items[i]); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 72,
                decoration: BoxDecoration(
                  color: active ? AppColors.dustyRose : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: active ? AppColors.terracotta : AppColors.divider, width: active ? 1.5 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_neckEmojis[widget.items[i]] ?? '🔘', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(widget.items[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: active ? AppColors.brick : AppColors.textMuted), maxLines: 2),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class _SleeveRow extends StatefulWidget {
  final List<String> items;
  final ValueChanged<String> onSelected;
  const _SleeveRow({required this.items, required this.onSelected});
  @override
  State<_SleeveRow> createState() => _SleeveRowState();
}

class _SleeveRowState extends State<_SleeveRow> {
  int _sel = 0;
  final _icons = {'Full Sleeve': '💪', 'Bell Sleeve': '🔔', 'Puff Sleeve': '☁️', 'Sleeveless': '💫', 'Cap Sleeve': '🧢', '3/4 Sleeve': '✂️', 'Half Sleeve': '✋'};
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: widget.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == _sel;
            return GestureDetector(
              onTap: () { setState(() => _sel = i); widget.onSelected(widget.items[i]); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 72,
                decoration: BoxDecoration(
                  color: active ? AppColors.blushLight : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: active ? AppColors.terracotta : AppColors.divider, width: active ? 1.5 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_icons[widget.items[i]] ?? '💪', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(widget.items[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: active ? AppColors.brick : AppColors.textMuted), maxLines: 2),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class _FabricSuggestionCard extends StatelessWidget {
  final String dressType;
  const _FabricSuggestionCard({required this.dressType});

  Map<String, dynamic> get _data {
    switch (dressType) {
      case 'Chudithar': return {'fabrics': ['Cotton', 'Chanderi', 'Georgette'], 'meters': '2.5–3 m', 'width': '44 inch', 'tip': 'Cotton is best for daily wear, Chanderi for occasions'};
      case 'Saree Blouse': return {'fabrics': ['Silk', 'Brocade', 'Raw Silk'], 'meters': '1 m', 'width': '44 inch', 'tip': 'Match blouse fabric with saree for a polished look'};
      case 'Lehenga': return {'fabrics': ['Net', 'Organza', 'Velvet'], 'meters': '5–6 m', 'width': '44 inch', 'tip': 'Use 3–4 m for skirt, 1 m for blouse, 2 m dupatta'};
      case 'Shirt': return {'fabrics': ['Cotton', 'Linen', 'Oxford'], 'meters': '2 m', 'width': '58 inch', 'tip': 'Linen is ideal for Indian summer climate'};
      default: return {'fabrics': ['Cotton', 'Georgette', 'Crepe'], 'meters': '2.5 m', 'width': '44 inch', 'tip': 'Soft draping fabrics work best for this silhouette'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recommended Fabrics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.espresso)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: (d['fabrics'] as List<String>).map((f) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.blushLight, borderRadius: BorderRadius.circular(20)),
            child: Text(f, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brick)),
          )).toList()),
          const SizedBox(height: 10),
          Row(children: [
            _InfoChip(label: 'Fabric', value: d['meters']),
            const SizedBox(width: 8),
            _InfoChip(label: 'Width', value: d['width']),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Text('💡 ', style: TextStyle(fontSize: 14)),
              Expanded(child: Text(d['tip'], style: const TextStyle(fontSize: 11, color: AppColors.walnut, height: 1.4))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  const _InfoChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.espresso)),
          ],
        ),
      );
}