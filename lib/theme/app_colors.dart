import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Light Mode (Pastel) ───
  static const Color lightBackground = Color(0xFFF8F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF2EFF8);
  static const Color lightPrimary = Color(0xFFB8A9C9);
  static const Color lightPrimaryDark = Color(0xFF9182A8);
  static const Color lightSecondary = Color(0xFFF2C4CE);
  static const Color lightAccent = Color(0xFFA8D8C8);
  static const Color lightTextPrimary = Color(0xFF2D2D3A);
  static const Color lightTextSecondary = Color(0xFF8E8E9A);
  static const Color lightTextHint = Color(0xFFB8B8C4);
  static const Color lightDivider = Color(0xFFEEECF2);

  // ─── Dark Mode ───
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF25253A);
  static const Color darkSurfaceVariant = Color(0xFF2F2F48);
  static const Color darkPrimary = Color(0xFFC4B5D8);
  static const Color darkPrimaryDark = Color(0xFFD8CCE8);
  static const Color darkSecondary = Color(0xFFF5D0D8);
  static const Color darkAccent = Color(0xFFB8E8D8);
  static const Color darkTextPrimary = Color(0xFFEAEAF0);
  static const Color darkTextSecondary = Color(0xFF9898A8);
  static const Color darkTextHint = Color(0xFF686878);
  static const Color darkDivider = Color(0xFF3A3A50);

  // ─── Subject Colors (shared) ───
  static const List<Color> subjectColors = [
    Color(0xFFB8A9C9), // 라벤더
    Color(0xFFF2C4CE), // 핑크
    Color(0xFFA8D8C8), // 민트
    Color(0xFFF5D5A0), // 피치
    Color(0xFFA8C8F0), // 스카이블루
    Color(0xFFF0B8B8), // 코랄
    Color(0xFFC8E0A8), // 라임
    Color(0xFFD8B8E8), // 퍼플
    Color(0xFFB8D8E8), // 아이스블루
    Color(0xFFF0D0B0), // 살몬
  ];

  // ─── Calendar Intensity (study hours heatmap) ───
  static const List<Color> lightCalendarIntensity = [
    Color(0x00B8A9C9), // 0시간 - 투명
    Color(0x33B8A9C9), // 1-2시간
    Color(0x66B8A9C9), // 2-4시간
    Color(0x99B8A9C9), // 4-6시간
    Color(0xCCB8A9C9), // 6-8시간
    Color(0xFFB8A9C9), // 8시간+
  ];

  static const List<Color> darkCalendarIntensity = [
    Color(0x00C4B5D8), // 0시간
    Color(0x33C4B5D8), // 1-2시간
    Color(0x66C4B5D8), // 2-4시간
    Color(0x99C4B5D8), // 4-6시간
    Color(0xCCC4B5D8), // 6-8시간
    Color(0xFFC4B5D8), // 8시간+
  ];

  static int intensityIndex(double hours) {
    if (hours <= 0) return 0;
    if (hours <= 2) return 1;
    if (hours <= 4) return 2;
    if (hours <= 6) return 3;
    if (hours <= 8) return 4;
    return 5;
  }
}
