import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';

class AppInfo {
  final String packageName;
  final String appName;
  final bool isWhitelisted;

  const AppInfo({
    required this.packageName,
    required this.appName,
    this.isWhitelisted = false,
  });

  AppInfo copyWith({bool? isWhitelisted}) => AppInfo(
        packageName: packageName,
        appName: appName,
        isWhitelisted: isWhitelisted ?? this.isWhitelisted,
      );
}

class WhitelistProvider extends ChangeNotifier {
  static const _channel = MethodChannel('com.gongsin.app/blocking');
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<AppInfo> _installedApps = [];
  List<AppInfo> _whitelistedApps = [];
  bool _isFocusModeActive = false;
  bool _isLoading = false;

  List<AppInfo> get installedApps => _installedApps;
  List<AppInfo> get whitelistedApps => _whitelistedApps;
  bool get isFocusModeActive => _isFocusModeActive;
  bool get isLoading => _isLoading;

  // Default system apps that should always be whitelisted
  static const defaultWhitelistPackages = [
    'com.android.dialer',      // 전화
    'com.samsung.android.dialer',
    'com.android.mms',          // 문자
    'com.samsung.android.messaging',
    'com.android.deskclock',    // 시계
    'com.sec.android.app.clockpackage',
    'com.android.calculator2',  // 계산기
    'com.sec.android.app.popupcalculator',
    'com.android.calendar',     // 캘린더
    'com.samsung.android.calendar',
  ];

  WhitelistProvider() {
    _loadFocusMode();
  }

  Future<void> _loadFocusMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isFocusModeActive = prefs.getBool('focus_mode_active') ?? false;
    notifyListeners();
  }

  Future<void> loadInstalledApps() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      final List<dynamic> apps = result as List<dynamic>;
      final whitelisted = await _db.getWhitelistedApps();
      final whitelistedPackages =
          whitelisted.map((w) => w['packageName'] as String).toSet();

      _installedApps = apps.map((app) {
        final map = Map<String, dynamic>.from(app as Map);
        final packageName = map['packageName'] as String;
        return AppInfo(
          packageName: packageName,
          appName: map['appName'] as String,
          isWhitelisted: whitelistedPackages.contains(packageName),
        );
      }).toList()
        ..sort((a, b) => a.appName.compareTo(b.appName));

      _whitelistedApps =
          _installedApps.where((a) => a.isWhitelisted).toList();
    } on PlatformException {
      // Platform channel not available (iOS or testing)
      _installedApps = [];
      _whitelistedApps = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleWhitelist(String packageName) async {
    final index =
        _installedApps.indexWhere((a) => a.packageName == packageName);
    if (index == -1) return;

    final app = _installedApps[index];
    if (app.isWhitelisted) {
      await _db.removeWhitelistedApp(packageName);
    } else {
      await _db.addWhitelistedApp(packageName, app.appName);
    }

    _installedApps[index] = app.copyWith(isWhitelisted: !app.isWhitelisted);
    _whitelistedApps =
        _installedApps.where((a) => a.isWhitelisted).toList();
    notifyListeners();

    if (_isFocusModeActive) {
      await _syncBlockingService();
    }
  }

  Future<void> startFocusMode() async {
    _isFocusModeActive = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('focus_mode_active', true);

    await _syncBlockingService();

    try {
      await _channel.invokeMethod('startBlocking');
    } on PlatformException {
      // Handle gracefully
    }
  }

  Future<void> stopFocusMode() async {
    _isFocusModeActive = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('focus_mode_active', false);

    try {
      await _channel.invokeMethod('stopBlocking');
    } on PlatformException {
      // Handle gracefully
    }
  }

  Future<void> _syncBlockingService() async {
    final whitelistedPackages =
        _whitelistedApps.map((a) => a.packageName).toList();
    try {
      await _channel.invokeMethod('updateWhitelist', {
        'packages': whitelistedPackages,
      });
    } on PlatformException {
      // Handle gracefully
    }
  }

  Future<bool> hasUsagePermission() async {
    try {
      final result = await _channel.invokeMethod('hasUsagePermission');
      return result as bool;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestUsagePermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } on PlatformException {
      // Handle gracefully
    }
  }

  Future<bool> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod('hasOverlayPermission');
      return result as bool;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException {
      // Handle gracefully
    }
  }
}
