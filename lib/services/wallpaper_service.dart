import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperPhoto {
  final String id;
  final String imageUrl;       // regular (1080px) for display
  final String thumbnailUrl;   // small (400px) for grid
  final String photographerName;
  final String photographerUrl;
  final String source;         // 'unsplash' or 'pixabay'
  final String downloadTrackUrl; // Unsplash download tracking endpoint

  const WallpaperPhoto({
    required this.id,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.photographerName,
    required this.photographerUrl,
    required this.source,
    this.downloadTrackUrl = '',
  });

  String get attribution {
    if (source == 'unsplash') {
      return 'Photo by $photographerName on Unsplash';
    }
    return 'Photo from Pixabay by $photographerName';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'thumbnailUrl': thumbnailUrl,
        'photographerName': photographerName,
        'photographerUrl': photographerUrl,
        'source': source,
        'downloadTrackUrl': downloadTrackUrl,
      };

  factory WallpaperPhoto.fromJson(Map<String, dynamic> json) => WallpaperPhoto(
        id: json['id'] as String,
        imageUrl: json['imageUrl'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String,
        photographerName: json['photographerName'] as String,
        photographerUrl: json['photographerUrl'] as String,
        source: json['source'] as String,
        downloadTrackUrl: json['downloadTrackUrl'] as String? ?? '',
      );
}

class WallpaperCategory {
  final String id;
  final String nameKo;
  final String nameEn;
  final String emoji;
  final String query;

  const WallpaperCategory({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.emoji,
    required this.query,
  });

  static const List<WallpaperCategory> all = [
    WallpaperCategory(id: 'nature', nameKo: '자연 풍경', nameEn: 'Nature', emoji: '🏔️', query: 'mountain landscape'),
    WallpaperCategory(id: 'aurora', nameKo: '오로라', nameEn: 'Aurora', emoji: '🌌', query: 'aurora borealis'),
    WallpaperCategory(id: 'ocean', nameKo: '바다', nameEn: 'Ocean', emoji: '🌊', query: 'ocean sunset'),
    WallpaperCategory(id: 'forest', nameKo: '숲', nameEn: 'Forest', emoji: '🌲', query: 'forest path'),
    WallpaperCategory(id: 'landmark', nameKo: '세계 랜드마크', nameEn: 'Landmarks', emoji: '🗼', query: 'famous landmark'),
    WallpaperCategory(id: 'city', nameKo: '도시 야경', nameEn: 'City Night', emoji: '🌃', query: 'city skyline night'),
    WallpaperCategory(id: 'cherry', nameKo: '벚꽃', nameEn: 'Cherry Blossom', emoji: '🌸', query: 'cherry blossom'),
    WallpaperCategory(id: 'space', nameKo: '우주', nameEn: 'Space', emoji: '✨', query: 'milky way stars'),
    WallpaperCategory(id: 'minimal', nameKo: '미니멀', nameEn: 'Minimal', emoji: '◻️', query: 'minimal gradient background'),
    WallpaperCategory(id: 'autumn', nameKo: '가을 단풍', nameEn: 'Autumn', emoji: '🍂', query: 'autumn leaves'),
  ];
}

class WallpaperService {
  // NOTE: In production, API keys must be managed through a backend proxy.
  // These are placeholder values -- replace with your actual keys or proxy URL.
  static const String _unsplashBaseUrl = 'https://api.unsplash.com';
  static const String _pixabayBaseUrl = 'https://pixabay.com/api';

  String? _unsplashApiKey;
  String? _pixabayApiKey;

  WallpaperService();

  Future<void> loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    _unsplashApiKey = prefs.getString('unsplash_api_key');
    _pixabayApiKey = prefs.getString('pixabay_api_key');
  }

  Future<void> setUnsplashKey(String key) async {
    _unsplashApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unsplash_api_key', key);
  }

  Future<void> setPixabayKey(String key) async {
    _pixabayApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pixabay_api_key', key);
  }

  bool get hasUnsplashKey => _unsplashApiKey != null && _unsplashApiKey!.isNotEmpty;
  bool get hasPixabayKey => _pixabayApiKey != null && _pixabayApiKey!.isNotEmpty;
  bool get hasAnyKey => hasUnsplashKey || hasPixabayKey;

  /// Fetch photos for a category. Tries Unsplash first, falls back to Pixabay.
  Future<List<WallpaperPhoto>> fetchPhotos({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    if (hasUnsplashKey) {
      try {
        return await _fetchFromUnsplash(query: query, page: page, perPage: perPage);
      } catch (_) {
        // Fall through to Pixabay
      }
    }

    if (hasPixabayKey) {
      try {
        return await _fetchFromPixabay(query: query, page: page, perPage: perPage);
      } catch (_) {
        // Return empty
      }
    }

    return [];
  }

  /// Fetch a random photo from Unsplash for the given query.
  Future<WallpaperPhoto?> fetchRandomPhoto({required String query}) async {
    if (hasUnsplashKey) {
      try {
        final uri = Uri.parse('$_unsplashBaseUrl/photos/random').replace(
          queryParameters: {
            'query': query,
            'orientation': 'portrait',
            'client_id': _unsplashApiKey!,
          },
        );
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return _parseUnsplashPhoto(data);
        }
      } catch (_) {}
    }

    if (hasPixabayKey) {
      try {
        final photos = await _fetchFromPixabay(query: query, page: 1, perPage: 5);
        if (photos.isNotEmpty) {
          return photos[Random().nextInt(photos.length)];
        }
      } catch (_) {}
    }

    return null;
  }

  /// Track a download event (required by Unsplash API terms).
  Future<void> trackDownload(WallpaperPhoto photo) async {
    if (photo.source == 'unsplash' && photo.downloadTrackUrl.isNotEmpty && hasUnsplashKey) {
      try {
        final uri = Uri.parse(photo.downloadTrackUrl).replace(
          queryParameters: {'client_id': _unsplashApiKey!},
        );
        await http.get(uri);
      } catch (_) {
        // Best effort -- don't block user flow
      }
    }
  }

  // ─── Unsplash ───

  Future<List<WallpaperPhoto>> _fetchFromUnsplash({
    required String query,
    required int page,
    required int perPage,
  }) async {
    final uri = Uri.parse('$_unsplashBaseUrl/search/photos').replace(
      queryParameters: {
        'query': query,
        'orientation': 'portrait',
        'page': '$page',
        'per_page': '$perPage',
        'client_id': _unsplashApiKey!,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Unsplash API error: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;

    return results
        .map((item) => _parseUnsplashPhoto(item as Map<String, dynamic>))
        .toList();
  }

  WallpaperPhoto _parseUnsplashPhoto(Map<String, dynamic> data) {
    final urls = data['urls'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final links = data['links'] as Map<String, dynamic>;

    return WallpaperPhoto(
      id: 'unsplash_${data['id']}',
      imageUrl: urls['regular'] as String,
      thumbnailUrl: urls['small'] as String,
      photographerName: user['name'] as String,
      photographerUrl:
          '${user['links']['html']}?utm_source=gongsin&utm_medium=referral',
      source: 'unsplash',
      downloadTrackUrl: links['download_location'] as String? ?? '',
    );
  }

  // ─── Pixabay ───

  Future<List<WallpaperPhoto>> _fetchFromPixabay({
    required String query,
    required int page,
    required int perPage,
  }) async {
    final uri = Uri.parse(_pixabayBaseUrl).replace(
      queryParameters: {
        'key': _pixabayApiKey!,
        'q': query,
        'image_type': 'photo',
        'orientation': 'vertical',
        'page': '$page',
        'per_page': '$perPage',
        'safesearch': 'true',
        'min_width': '1080',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Pixabay API error: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final hits = data['hits'] as List<dynamic>;

    return hits.map((item) {
      final map = item as Map<String, dynamic>;
      return WallpaperPhoto(
        id: 'pixabay_${map['id']}',
        imageUrl: map['largeImageURL'] as String,
        thumbnailUrl: map['webformatURL'] as String,
        photographerName: map['user'] as String,
        photographerUrl: map['pageURL'] as String,
        source: 'pixabay',
      );
    }).toList();
  }
}
