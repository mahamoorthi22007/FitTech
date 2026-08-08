import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Pexels API Key ───────────────────────────────────────────────────────────
// Replace with your key from https://www.pexels.com/api/
const String kPexelsApiKey = '9yfBEKoXdruIG58fJi92xEMN3P0XwAOszFxzRK1aamPO9dX80EBFsu6s';

class PexelsPhoto {
  final int id;
  final String photographer;
  final String smallUrl;
  final String mediumUrl;
  final String largeUrl;
  final String originalUrl;
  final int width;
  final int height;
  final String alt;

  const PexelsPhoto({
    required this.id,
    required this.photographer,
    required this.smallUrl,
    required this.mediumUrl,
    required this.largeUrl,
    required this.originalUrl,
    required this.width,
    required this.height,
    required this.alt,
  });

  factory PexelsPhoto.fromJson(Map<String, dynamic> json) {
    final src = json['src'] as Map<String, dynamic>;
    return PexelsPhoto(
      id: json['id'],
      photographer: json['photographer'] ?? '',
      smallUrl: src['small'] ?? '',
      mediumUrl: src['medium'] ?? '',
      largeUrl: src['large'] ?? '',
      originalUrl: src['original'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      alt: json['alt'] ?? '',
    );
  }

  double get aspectRatio => width > 0 && height > 0 ? width / height : 0.75;
}

class PexelsService {
  static const _base = 'https://api.pexels.com/v1';
  static final _cache = <String, List<PexelsPhoto>>{};

  // ── Search queries per category ────────────────────────────────────────────
  // All queries are crafted to return clothing/fabric ONLY (no faces)
  static const Map<String, List<String>> categoryQueries = {
    // Girls / Women
    'blouse': [
      'silk blouse fabric close up no people',
      'designer blouse embroidery detail',
      'saree blouse back design fabric',
    ],
    'chudithar': [
      'salwar kameez hanging display',
      'churidar suit fashion flat lay',
      'indian kurti dress mannequin',
    ],
    'saree': [
      'silk saree draped no person',
      'saree fabric pleats close up',
      'banarasi saree textile detail',
    ],
    'lehenga': [
      'lehenga skirt detail embroidery',
      'bridal lehenga fabric close up',
      'lehnga choli fabric texture',
    ],
    'anarkali': [
      'anarkali suit flat lay fashion',
      'long anarkali dress display',
      'ethnic anarkali fabric print',
    ],
    'girls_all': [
      'indian women fashion outfit flatlay',
      'ethnic dress collection display',
      'traditional indian clothing fabric',
      'salwar suit embroidery close up',
      'indian festival clothing detail',
    ],

    // Boys / Men
    'kurta': [
      'kurta fabric texture close up',
      'men kurta display no people',
      'cotton kurta hanging wardrobe',
    ],
    'shirt': [
      'mens formal shirt flat lay',
      'linen shirt fabric texture',
      'dress shirt collar close up',
    ],
    'suit': [
      'mens suit jacket display',
      'formal blazer fabric texture',
      'wedding sherwani fabric detail',
    ],
    'boys_all': [
      'mens indian fashion outfit flatlay',
      'sherwani bandhgala display',
      'ethnic men clothing fabric detail',
      'kurta pyjama flat lay',
      'mens traditional wear display',
    ],

    // Kids
    'girls_kids': [
      'kids dress display flat lay',
      'children frock fabric detail',
      'girl party dress hanging',
      'kids ethnic wear display',
      'colorful children dress collection',
    ],
    'boys_kids': [
      'kids kurta set display',
      'boys ethnic wear flat lay',
      'children suit formal display',
      'boys party wear fabric detail',
    ],

    // Western
    'casual': [
      'casual wear outfit flat lay',
      'jeans tshirt fashion flatlay',
      'western outfit display no person',
    ],
    'western_women': [
      'western dress fabric display',
      'womens casual outfit flat lay',
      'fashion dress hanging wardrobe',
    ],

    // Fabric / Textile
    'fabric': [
      'silk fabric texture close up',
      'cotton textile colorful pattern',
      'embroidery fabric detail macro',
      'indian textile pattern surface',
      'brocade silk weave close up',
    ],

    // Aari / Embroidery
    'aari': [
      'embroidery thread work fabric',
      'zari embroidery close up',
      'aari embroidery detail textile',
      'gold thread embroidery fabric',
      'hand embroidery pattern macro',
    ],

    // Home hero carousel
    'hero': [
      'fashion textile fabric colorful',
      'indian ethnic wear collection',
      'silk fabric drape close up',
      'fashion design studio fabric',
      'colorful thread spool collection',
    ],
  };

  /// Fetch photos for a category. Returns cached result if available.
  static Future<List<PexelsPhoto>> fetchCategory(
    String category, {
    int perPage = 20,
    int page = 1,
  }) async {
    final cacheKey = '$category-$page';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final queries = categoryQueries[category] ?? categoryQueries['hero']!;
    // Rotate query based on page to get variety
    final query = queries[(page - 1) % queries.length];

    return _search(query, perPage: perPage, page: page, cacheKey: cacheKey);
  }

  static Future<List<PexelsPhoto>> fetchByQuery(
    String query, {
    int perPage = 20,
    int page = 1,
  }) async {
    final cacheKey = '$query-$page';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    return _search(query, perPage: perPage, page: page, cacheKey: cacheKey);
  }

  static Future<List<PexelsPhoto>> _search(
    String query, {
    required int perPage,
    required int page,
    required String cacheKey,
  }) async {
    try {
      final uri = Uri.parse(
        '$_base/search?query=${Uri.encodeComponent(query)}&per_page=$perPage&page=$page&orientation=portrait',
      );
      final response = await http.get(uri, headers: {'Authorization': kPexelsApiKey});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final photos = (data['photos'] as List)
            .map((p) => PexelsPhoto.fromJson(p as Map<String, dynamic>))
            .toList();
        _cache[cacheKey] = photos;
        return photos;
      }
    } catch (e) {
      // ignore — return fallback
    }
    return [];
  }

  static void clearCache() => _cache.clear();
}
