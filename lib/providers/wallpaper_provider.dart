import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wallpaper_service.dart';

class WallpaperProvider extends ChangeNotifier {
  final WallpaperService _service = WallpaperService();

  WallpaperPhoto? _currentPhoto;
  List<WallpaperPhoto> _categoryPhotos = [];
  WallpaperCategory _selectedCategory = WallpaperCategory.all.first;
  bool _isLoading = false;
  bool _autoChange = true;
  String? _error;

  WallpaperPhoto? get currentPhoto => _currentPhoto;
  List<WallpaperPhoto> get categoryPhotos => _categoryPhotos;
  WallpaperCategory get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get autoChange => _autoChange;
  String? get error => _error;
  bool get hasApiKey => _service.hasAnyKey;

  WallpaperProvider() {
    _init();
  }

  Future<void> _init() async {
    await _service.loadApiKeys();
    await _loadSavedState();

    // Auto-fetch new wallpaper if auto-change is on and it's a new day
    if (_autoChange && _service.hasAnyKey) {
      final shouldRefresh = await _shouldRefreshToday();
      if (shouldRefresh) {
        await fetchDailyWallpaper();
      }
    }

    notifyListeners();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();

    _autoChange = prefs.getBool('wallpaper_auto_change') ?? true;

    final categoryId = prefs.getString('wallpaper_category') ?? 'nature';
    _selectedCategory = WallpaperCategory.all.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => WallpaperCategory.all.first,
    );

    final savedPhoto = prefs.getString('wallpaper_current');
    if (savedPhoto != null) {
      try {
        _currentPhoto = WallpaperPhoto.fromJson(
          json.decode(savedPhoto) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
  }

  Future<bool> _shouldRefreshToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getString('wallpaper_last_fetch');
    if (lastFetch == null) return true;

    final lastDate = DateTime.tryParse(lastFetch);
    if (lastDate == null) return true;

    final now = DateTime.now();
    return now.year != lastDate.year ||
        now.month != lastDate.month ||
        now.day != lastDate.day;
  }

  Future<void> _markFetchedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'wallpaper_last_fetch',
      DateTime.now().toIso8601String(),
    );
  }

  /// Set API keys (called from settings)
  Future<void> setUnsplashKey(String key) async {
    await _service.setUnsplashKey(key);
    notifyListeners();
  }

  Future<void> setPixabayKey(String key) async {
    await _service.setPixabayKey(key);
    notifyListeners();
  }

  /// Select a category and fetch photos
  Future<void> selectCategory(WallpaperCategory category) async {
    _selectedCategory = category;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallpaper_category', category.id);

    await fetchCategoryPhotos();
  }

  /// Fetch photos for the current category
  Future<void> fetchCategoryPhotos() async {
    if (!_service.hasAnyKey) {
      _error = 'API 키를 설정해주세요 (설정 > 배경화면)';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categoryPhotos = await _service.fetchPhotos(
        query: _selectedCategory.query,
        perPage: 20,
      );
    } catch (e) {
      _error = '배경화면을 불러오는 데 실패했습니다';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set a photo as the current wallpaper
  Future<void> setWallpaper(WallpaperPhoto photo) async {
    _currentPhoto = photo;
    notifyListeners();

    // Track download (required by Unsplash API terms)
    await _service.trackDownload(photo);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallpaper_current', json.encode(photo.toJson()));
  }

  /// Fetch a random daily wallpaper
  Future<void> fetchDailyWallpaper() async {
    if (!_service.hasAnyKey) return;

    _isLoading = true;
    notifyListeners();

    try {
      final photo = await _service.fetchRandomPhoto(
        query: _selectedCategory.query,
      );
      if (photo != null) {
        _currentPhoto = photo;
        await _service.trackDownload(photo);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wallpaper_current', json.encode(photo.toJson()));
        await _markFetchedToday();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Manually refresh wallpaper (user taps refresh)
  Future<void> refreshWallpaper() async {
    await fetchDailyWallpaper();
  }

  /// Toggle auto-change setting
  Future<void> setAutoChange(bool value) async {
    _autoChange = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wallpaper_auto_change', value);
  }
}
