import 'dart:math';
import '../domain/status_effect_system.dart';
import '../domain/weapon_system.dart';

/// Weapon special effect processor (Pure Dart)
/// Bridges weapon specialEffectKey to actual combat effects.
/// Decoupled from Flame - takes damage context and returns effects to apply.
class WeaponEffectProcessor {
  static final _rng = Random();

  /// Process weapon special effects on attack hit
  /// Returns a list of StatusEffects to apply to the target
  static List<StatusEffect> processOnHit({
    required List<WeaponData?> equippedWeapons,
    required List<WeaponData> equippedItems,
    required double baseDamage,
    double statusEffectiveness = 1.0,
  }) {
    final effects = <StatusEffect>[];

    // Process weapon effects
    for (final weapon in equippedWeapons) {
      if (weapon == null || weapon.specialEffectKey == null) continue;
      _processEffectKey(
        weapon.specialEffectKey!,
        weapon.quality,
        baseDamage,
        statusEffectiveness,
        effects,
      );
    }

    // Process item effects (passive items with special_effect_key)
    for (final item in equippedItems) {
      if (item.specialEffectKey == null) continue;
      _processEffectKey(
        item.specialEffectKey!,
        item.quality,
        baseDamage,
        statusEffectiveness,
        effects,
      );
    }

    return effects;
  }

  static void _processEffectKey(
    String effectKey,
    WeaponQuality quality,
    double baseDamage,
    double statusEffectiveness,
    List<StatusEffect> effects,
  ) {
    switch (effectKey) {
      // ===== Original weapon effects =====
      case 'burn_chance':
        final chance = 0.10 + quality.index * 0.05 +
            (quality == WeaponQuality.legendary ? 0.05 : 0);
        if (_rng.nextDouble() < chance) {
          final burnDmg = baseDamage * 0.3 * (1 + quality.index * 0.2);
          effects.add(StatusEffect(
            type: StatusEffectType.burn,
            duration: 3.0 * statusEffectiveness,
            magnitude: burnDmg,
          ));
        }

      case 'poison_on_hit':
        final poisonDmg = 2.0 + quality.index * 1.5;
        effects.add(StatusEffect(
          type: StatusEffectType.poison,
          duration: 4.0 * statusEffectiveness,
          magnitude: poisonDmg,
        ));

      case 'freeze_chance':
        final chance = 0.08 + quality.index * 0.04;
        if (_rng.nextDouble() < chance) {
          effects.add(StatusEffect(
            type: StatusEffectType.freeze,
            duration: 1.0 + quality.index * 0.3,
            magnitude: 1.0,
          ));
        }

      case 'bleed_on_crit':
        final bleedDmg = baseDamage * 0.15 * (1 + quality.index * 0.15);
        effects.add(StatusEffect(
          type: StatusEffectType.bleed,
          duration: 3.0,
          magnitude: bleedDmg,
        ));

      case 'vulnerable_on_hit':
        final chance = 0.12 + quality.index * 0.05;
        if (_rng.nextDouble() < chance) {
          effects.add(StatusEffect(
            type: StatusEffectType.vulnerable,
            duration: 2.5 * statusEffectiveness,
            magnitude: 1.0,
          ));
        }

      // ===== New weapon effects =====

      case 'pierce':
        // Pierce: 穿透邏輯由 SurvivalGameWorld 處理
        // 此處附加小量額外傷害作為穿透指示
        break;

      case 'multi_shot':
        // Shotgun: 多發射擊 → 數值模擬為多層短時流血
        final bleedPerShot = baseDamage * 0.08;
        for (int i = 0; i < 3; i++) {
          effects.add(StatusEffect(
            type: StatusEffectType.bleed,
            duration: 1.5,
            magnitude: bleedPerShot,
          ));
        }

      case 'poison_cloud':
        // 毒雲：高疊加中毒
        final poisonDmg = 1.5 + quality.index * 1.0;
        for (int i = 0; i < 3; i++) {
          effects.add(StatusEffect(
            type: StatusEffectType.poison,
            duration: 5.0 * statusEffectiveness,
            magnitude: poisonDmg,
          ));
        }

      case 'chain_lightning':
        // 閃電彈跳：對目標施加脆弱（模擬連鎖傷害擴散）
        effects.add(StatusEffect(
          type: StatusEffectType.vulnerable,
          duration: 2.0 * statusEffectiveness,
          magnitude: 1.0,
        ));

      case 'stun_chance':
        // 巨錘：10% 暈眩
        if (_rng.nextDouble() < 0.10 + quality.index * 0.03) {
          effects.add(StatusEffect(
            type: StatusEffectType.stun,
            duration: 1.0 + quality.index * 0.2,
            magnitude: 1.0,
          ));
        }

      case 'return_hit':
        // 迴旋鏢：模擬雙擊 → 額外一次流血
        effects.add(StatusEffect(
          type: StatusEffectType.bleed,
          duration: 2.0,
          magnitude: baseDamage * 0.3,
        ));

      case 'orbit_aura':
        // 神聖經文：持續燃燒光環
        effects.add(StatusEffect(
          type: StatusEffectType.burn,
          duration: 2.0 * statusEffectiveness,
          magnitude: baseDamage * 0.15,
        ));

      case 'aoe_explosion':
        // 手榴彈：大範圍 → 脆弱 + 暈眩
        effects.add(StatusEffect(
          type: StatusEffectType.vulnerable,
          duration: 3.0,
          magnitude: 1.0,
        ));
        if (_rng.nextDouble() < 0.3) {
          effects.add(StatusEffect(
            type: StatusEffectType.stun,
            duration: 0.8,
            magnitude: 1.0,
          ));
        }

      case 'spike_burst':
        // 仙人掌棒：4方向刺 → 4層流血
        for (int i = 0; i < 4; i++) {
          effects.add(StatusEffect(
            type: StatusEffectType.bleed,
            duration: 2.0,
            magnitude: baseDamage * 0.05,
          ));
        }

      case 'harvest':
        // 收割鐮刀：增加掉落 → 以脆弱模擬（提高傷害 = 加速擊殺）
        effects.add(StatusEffect(
          type: StatusEffectType.vulnerable,
          duration: 2.0,
          magnitude: 1.0,
        ));

      case 'homing':
        // 魔法球：自動追蹤 → 數值上表現為更穩定的傷害
        // 無額外狀態，追蹤邏輯由遊戲世界層處理
        break;

      case 'thorns_reflect':
        // 尖刺盾：反彈由遊戲世界層在受傷時處理
        break;

      case 'spawn_turret':
        // 扳手：砲塔生成由遊戲世界層處理
        break;

      // ===== Item passive effects =====

      case 'poison_chance_15':
        // 毒藥瓶：15% 中毒機率
        if (_rng.nextDouble() < 0.15) {
          effects.add(StatusEffect(
            type: StatusEffectType.poison,
            duration: 4.0 * statusEffectiveness,
            magnitude: 2.0,
          ));
        }

      case 'burn_spread':
        // 汽油桶：攻擊有機率附加擴散燃燒
        if (_rng.nextDouble() < 0.20) {
          effects.add(StatusEffect(
            type: StatusEffectType.burn,
            duration: 4.0 * statusEffectiveness,
            magnitude: baseDamage * 0.2,
          ));
        }

      case 'bleed_enhance':
        // 釘鞋：增強流血
        effects.add(StatusEffect(
          type: StatusEffectType.bleed,
          duration: 3.0,
          magnitude: baseDamage * 0.1,
        ));

      case 'frost_retaliate':
        // 冰霜護符：受擊凍結 → 由遊戲世界層在受傷時處理
        break;

      case 'poison_stack_double':
        // 腐蝕酸液：中毒疊加加倍 → 額外加一層毒
        effects.add(StatusEffect(
          type: StatusEffectType.poison,
          duration: 4.0 * statusEffectiveness,
          magnitude: 1.5,
        ));

      case 'vuln_bonus_dmg':
        // 弱點分析儀：對脆弱目標 +20% → 由遊戲世界層計算
        break;
    }
  }

  /// Process augment-based special effects
  static List<StatusEffect> processAugmentEffects({
    required Set<String> activeAugmentEffects,
    required double baseDamage,
  }) {
    final effects = <StatusEffect>[];

    if (activeAugmentEffects.contains('attacks_burn')) {
      if (_rng.nextDouble() < 0.25) {
        effects.add(StatusEffect(
          type: StatusEffectType.burn,
          duration: 3.0,
          magnitude: baseDamage * 0.2,
        ));
      }
    }

    return effects;
  }
}
