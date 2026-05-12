import 'package:flutter/material.dart';

/// 遊戲配色系統
/// 定義品質顏色、UI 主題色與特效顏色
class GameColors {
  GameColors._();

  // ===== 背景與表面 =====
  static const Color backgroundDark = Color(0xFF0A0E1A);
  static const Color surfaceDark = Color(0xFF141B2D);
  static const Color surfaceLight = Color(0xFF1E2A3A);
  static const Color cardBackground = Color(0xFF1A2332);

  // ===== 強調色 =====
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentRed = Color(0xFFFF4444);
  static const Color accentGreen = Color(0xFF4CAF50);

  // ===== 武器品質顏色 =====
  static const Color qualityNormal = Color(0xFFB0BEC5);   // 白色 (普通)
  static const Color qualityFine = Color(0xFF42A5F5);      // 藍色 (優秀)
  static const Color qualityExcellent = Color(0xFFAB47BC); // 紫色 (精良)
  static const Color qualityLegendary = Color(0xFFEF5350); // 紅色 (傳奇)

  /// 根據品質等級取得對應顏色
  static Color getQualityColor(int quality) {
    switch (quality) {
      case 0: return qualityNormal;
      case 1: return qualityFine;
      case 2: return qualityExcellent;
      case 3: return qualityLegendary;
      default: return qualityNormal;
    }
  }

  // ===== 異常狀態顏色 =====
  static const Color statusPoison = Color(0xFF76FF03);
  static const Color statusBurn = Color(0xFFFF6D00);
  static const Color statusFreeze = Color(0xFF40C4FF);
  static const Color statusBleed = Color(0xFFD50000);
  static const Color statusVulnerable = Color(0xFFFFEB3B);
  static const Color statusStun = Color(0xFFFFFFFF);

  // ===== 血量漸層 =====
  static const Color healthHigh = Color(0xFF4CAF50);
  static const Color healthMid = Color(0xFFFFC107);
  static const Color healthLow = Color(0xFFF44336);
  static const Color healthCritical = Color(0xFFD32F2F);

  // ===== Vignette 回饋 =====
  static const Color vignetteDark = Color(0xCC000000);
  static const Color vignetteRed = Color(0x88FF0000);

  // ===== Google 模擬登入 =====
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleRed = Color(0xFFDB4437);
  static const Color googleYellow = Color(0xFFF4B400);
  static const Color googleGreen = Color(0xFF0F9D58);
}
