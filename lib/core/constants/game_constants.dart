/// 遊戲全域常數定義
/// 所有遊戲數值均集中於此，避免 Hardcode
/// 後續可改為從 JSON 配置檔讀取
class GameConstants {
  GameConstants._();

  // ===== 波次設定 =====
  static late double waveDurationSeconds;
  static late int augmentInterval;

  // ===== 敵人設定 =====
  static late int maxEnemiesOnField;
  static late int maxEnemiesOnScreen;
  static late int baseEnemyCount;
  static late double baseSpawnInterval;
  static late double enemyOverflowDmgPerSecond;

  // ===== 商店設定 =====
  static late int shopSlotCount;
  static late int shopRerollCost;

  // ===== 武器品質 =====
  static const int qualityNormal = 0;
  static const int qualityFine = 1;
  static const int qualityExcellent = 2;
  static const int qualityLegendary = 3;

  // ===== 武器格子 =====
  static late int maxWeaponSlots;

  // ===== 異常狀態 =====
  static late double poisonDamagePerSecond;
  static late double burnDamagePerSecond;
  static late double freezeDuration;
  static late double freezeSlowDuration;
  static late double vulnerableDamageMultiplier;

  // ===== 視覺回饋 =====
  static late double hurtFlashDuration;
  static late double lowHealthThreshold;
  static late double criticalHealthThreshold;

  // ===== 動畫參數 =====
  static late double idleBreathCycle;
  static late double walkBobbingCycle;

  // ===== 經濟 =====
  static late int baseWaveGold;
  static late int baseKillGold;

  static void init(Map<String, dynamic> data) {
    waveDurationSeconds = (data['waveDurationSeconds'] as num).toDouble();
    augmentInterval = data['augmentInterval'] as int;
    maxEnemiesOnField = data['maxEnemiesOnField'] as int;
    maxEnemiesOnScreen = data['maxEnemiesOnScreen'] as int;
    baseEnemyCount = data['baseEnemyCount'] as int;
    baseSpawnInterval = (data['baseSpawnInterval'] as num).toDouble();
    enemyOverflowDmgPerSecond = (data['enemyOverflowDmgPerSecond'] as num).toDouble();
    shopSlotCount = data['shopSlotCount'] as int;
    shopRerollCost = data['shopRerollCost'] as int;
    maxWeaponSlots = data['maxWeaponSlots'] as int;
    poisonDamagePerSecond = (data['poisonDamagePerSecond'] as num).toDouble();
    burnDamagePerSecond = (data['burnDamagePerSecond'] as num).toDouble();
    freezeDuration = (data['freezeDuration'] as num).toDouble();
    freezeSlowDuration = (data['freezeSlowDuration'] as num).toDouble();
    vulnerableDamageMultiplier = (data['vulnerableDamageMultiplier'] as num).toDouble();
    hurtFlashDuration = (data['hurtFlashDuration'] as num).toDouble();
    lowHealthThreshold = (data['lowHealthThreshold'] as num).toDouble();
    criticalHealthThreshold = (data['criticalHealthThreshold'] as num).toDouble();
    idleBreathCycle = (data['idleBreathCycle'] as num).toDouble();
    walkBobbingCycle = (data['walkBobbingCycle'] as num).toDouble();
    baseWaveGold = data['baseWaveGold'] as int;
    baseKillGold = data['baseKillGold'] as int;
  }
}
