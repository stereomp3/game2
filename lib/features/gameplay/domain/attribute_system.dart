/// 遊戲實體屬性系統（純 Dart，不依賴 Flutter/Flame）
///
/// 設計原則：屬性本身是純數值，所有加成透過 copyWith 產生新實例，
/// 保持 immutable 風格以確保狀態可預測性
class EntityStats {
  // ===== 生存屬性 =====
  final double maxHp;
  final double hpRegen;       // 每秒
  final double lifesteal;     // %
  final double armor;         // 減傷比例 0~1
  final double dodge;         // 閃避率 0~1
  final double moveSpeed;     // px/s

  // ===== 攻擊屬性 =====
  final double meleeDmg;
  final double rangedDmg;
  final double elementalDmg;
  final double attackSpeed;   // 攻擊間隔乘數 (1.0 = 標準)
  final double critChance;    // 0~1
  final double critDamage;    // 倍率，1.5 = 150%
  final double range;         // px

  // ===== 進階屬性 =====
  final double knockback;
  final double cooldownReduction;  // 0~1
  final double pickupRadius;
  final double luck;               // 影響商店品質

  // ===== 異常狀態專屬 =====
  final double debuffDuration;        // 倍率
  final double statusEffectiveness;   // 倍率

  const EntityStats({
    this.maxHp = 100,
    this.hpRegen = 0,
    this.lifesteal = 0,
    this.armor = 0,
    this.dodge = 0,
    this.moveSpeed = 100,
    this.meleeDmg = 10,
    this.rangedDmg = 10,
    this.elementalDmg = 5,
    this.attackSpeed = 1.0,
    this.critChance = 0.05,
    this.critDamage = 1.5,
    this.range = 100,
    this.knockback = 10,
    this.cooldownReduction = 0,
    this.pickupRadius = 50,
    this.luck = 0,
    this.debuffDuration = 1.0,
    this.statusEffectiveness = 1.0,
  });

  /// 計算實際傷害減免後的受傷值
  double calculateDamageReceived(double rawDamage) {
    final reduced = rawDamage * (1.0 - armor.clamp(0.0, 0.9));
    return reduced < 1 ? 1 : reduced;
  }

  /// 計算爆擊後的傷害值
  double applyCrit(double damage) {
    final roll = _random();
    return roll < critChance ? damage * critDamage : damage;
  }

  /// 偽隨機數（純函數替代，實際使用時應注入 Random）
  double _random() => (DateTime.now().microsecondsSinceEpoch % 1000) / 1000.0;

  /// 合并加成（用於裝備效果疊加）
  EntityStats add(EntityStats bonus) {
    return EntityStats(
      maxHp: maxHp + bonus.maxHp,
      hpRegen: hpRegen + bonus.hpRegen,
      lifesteal: (lifesteal + bonus.lifesteal).clamp(0, 1),
      armor: (armor + bonus.armor).clamp(0, 0.9),
      dodge: (dodge + bonus.dodge).clamp(0, 0.95),
      moveSpeed: moveSpeed + bonus.moveSpeed,
      meleeDmg: meleeDmg + bonus.meleeDmg,
      rangedDmg: rangedDmg + bonus.rangedDmg,
      elementalDmg: elementalDmg + bonus.elementalDmg,
      attackSpeed: (attackSpeed * bonus.attackSpeed).clamp(0.2, 5.0),
      critChance: (critChance + bonus.critChance).clamp(0, 1),
      critDamage: critDamage + bonus.critDamage,
      range: range + bonus.range,
      knockback: knockback + bonus.knockback,
      cooldownReduction: (cooldownReduction + bonus.cooldownReduction).clamp(0, 0.8),
      pickupRadius: pickupRadius + bonus.pickupRadius,
      luck: luck + bonus.luck,
      debuffDuration: debuffDuration * bonus.debuffDuration,
      statusEffectiveness: statusEffectiveness * bonus.statusEffectiveness,
    );
  }

  EntityStats copyWith({
    double? maxHp, double? hpRegen, double? lifesteal, double? armor,
    double? dodge, double? moveSpeed, double? meleeDmg, double? rangedDmg,
    double? elementalDmg, double? attackSpeed, double? critChance,
    double? critDamage, double? range, double? knockback,
    double? cooldownReduction, double? pickupRadius, double? luck,
    double? debuffDuration, double? statusEffectiveness,
  }) {
    return EntityStats(
      maxHp: maxHp ?? this.maxHp,
      hpRegen: hpRegen ?? this.hpRegen,
      lifesteal: lifesteal ?? this.lifesteal,
      armor: armor ?? this.armor,
      dodge: dodge ?? this.dodge,
      moveSpeed: moveSpeed ?? this.moveSpeed,
      meleeDmg: meleeDmg ?? this.meleeDmg,
      rangedDmg: rangedDmg ?? this.rangedDmg,
      elementalDmg: elementalDmg ?? this.elementalDmg,
      attackSpeed: attackSpeed ?? this.attackSpeed,
      critChance: critChance ?? this.critChance,
      critDamage: critDamage ?? this.critDamage,
      range: range ?? this.range,
      knockback: knockback ?? this.knockback,
      cooldownReduction: cooldownReduction ?? this.cooldownReduction,
      pickupRadius: pickupRadius ?? this.pickupRadius,
      luck: luck ?? this.luck,
      debuffDuration: debuffDuration ?? this.debuffDuration,
      statusEffectiveness: statusEffectiveness ?? this.statusEffectiveness,
    );
  }
}
