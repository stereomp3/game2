import 'dart:math';

/// Augment definition (Pure Dart)
/// Augments are powerful permanent buffs chosen every N waves
class AugmentData {
  final String id;
  final String nameKey;
  final String descKey;
  final String iconName;
  final Map<String, double> statBonuses;
  final String? specialEffect;

  const AugmentData({
    required this.id,
    required this.nameKey,
    required this.descKey,
    this.iconName = 'star',
    this.statBonuses = const {},
    this.specialEffect,
  });
}

/// Augment pool (32 total: 12 original + 20 new)
class AugmentDatabase {
  static final _random = Random();

  static const List<AugmentData> _allAugments = [
    // ===== Original 12 =====
    // Offensive
    AugmentData(
      id: 'berserker',
      nameKey: 'augment_berserker',
      descKey: 'augment_berserker_desc',
      iconName: 'sword',
      statBonuses: {'melee_dmg': 8.0, 'attack_speed': 0.15},
    ),
    AugmentData(
      id: 'sharpshooter',
      nameKey: 'augment_sharpshooter',
      descKey: 'augment_sharpshooter_desc',
      iconName: 'target',
      statBonuses: {'ranged_dmg': 10.0, 'crit_chance': 0.1},
    ),
    AugmentData(
      id: 'pyromancer',
      nameKey: 'augment_pyromancer',
      descKey: 'augment_pyromancer_desc',
      iconName: 'fire',
      statBonuses: {'elemental_dmg': 12.0},
      specialEffect: 'attacks_burn',
    ),
    AugmentData(
      id: 'executioner',
      nameKey: 'augment_executioner',
      descKey: 'augment_executioner_desc',
      iconName: 'skull',
      statBonuses: {'crit_damage': 0.5, 'crit_chance': 0.05},
    ),

    // Defensive
    AugmentData(
      id: 'iron_skin',
      nameKey: 'augment_iron_skin',
      descKey: 'augment_iron_skin_desc',
      iconName: 'shield',
      statBonuses: {'armor': 0.08, 'max_hp': 25.0},
    ),
    AugmentData(
      id: 'regeneration',
      nameKey: 'augment_regeneration',
      descKey: 'augment_regeneration_desc',
      iconName: 'heart',
      statBonuses: {'hp_regen': 3.0, 'lifesteal': 0.05},
    ),
    AugmentData(
      id: 'phantom',
      nameKey: 'augment_phantom',
      descKey: 'augment_phantom_desc',
      iconName: 'ghost',
      statBonuses: {'dodge': 0.12, 'move_speed': 15.0},
    ),
    AugmentData(
      id: 'fortress',
      nameKey: 'augment_fortress',
      descKey: 'augment_fortress_desc',
      iconName: 'castle',
      statBonuses: {'max_hp': 50.0, 'armor': 0.05},
      specialEffect: 'thorns',
    ),

    // Utility
    AugmentData(
      id: 'treasure_hunter',
      nameKey: 'augment_treasure_hunter',
      descKey: 'augment_treasure_hunter_desc',
      iconName: 'coin',
      statBonuses: {'luck': 15.0, 'pickup_radius': 30.0},
    ),
    AugmentData(
      id: 'plague_doctor',
      nameKey: 'augment_plague_doctor',
      descKey: 'augment_plague_doctor_desc',
      iconName: 'potion',
      statBonuses: {'debuff_duration': 0.5, 'status_effectiveness': 0.3},
      specialEffect: 'debuff_spread',
    ),
    AugmentData(
      id: 'time_warp',
      nameKey: 'augment_time_warp',
      descKey: 'augment_time_warp_desc',
      iconName: 'clock',
      statBonuses: {'cooldown_reduction': 0.15, 'attack_speed': 0.1},
    ),
    AugmentData(
      id: 'vampiric',
      nameKey: 'augment_vampiric',
      descKey: 'augment_vampiric_desc',
      iconName: 'blood',
      statBonuses: {'lifesteal': 0.08, 'melee_dmg': 5.0},
    ),

    // ===== Category 1: Economy & Meta (5) =====
    AugmentData(
      id: 'trade_sector',
      nameKey: 'augment_trade_sector',
      descKey: 'augment_trade_sector_desc',
      iconName: 'store',
      specialEffect: 'free_reroll',
    ),
    AugmentData(
      id: 'rich_get_richer',
      nameKey: 'augment_rich_get_richer',
      descKey: 'augment_rich_get_richer_desc',
      iconName: 'coin',
      specialEffect: 'gold_interest',
    ),
    AugmentData(
      id: 'scrap_recycling',
      nameKey: 'augment_scrap_recycling',
      descKey: 'augment_scrap_recycling_desc',
      iconName: 'recycle',
      specialEffect: 'sell_hp_bonus',
    ),
    AugmentData(
      id: 'vip_customer',
      nameKey: 'augment_vip_customer',
      descKey: 'augment_vip_customer_desc',
      iconName: 'crown',
      specialEffect: 'quality_boost',
    ),
    AugmentData(
      id: 'pandora_items',
      nameKey: 'augment_pandora_items',
      descKey: 'augment_pandora_items_desc',
      iconName: 'gift',
      specialEffect: 'pandora_upgrade',
    ),

    // ===== Category 2: Combat Stats (5) =====
    AugmentData(
      id: 'glass_cannon',
      nameKey: 'augment_glass_cannon',
      descKey: 'augment_glass_cannon_desc',
      iconName: 'explosion',
      statBonuses: {'melee_dmg': 15.0, 'ranged_dmg': 15.0, 'elemental_dmg': 15.0},
      specialEffect: 'glass_cannon',
    ),
    AugmentData(
      id: 'adrenaline_rush',
      nameKey: 'augment_adrenaline_rush',
      descKey: 'augment_adrenaline_rush_desc',
      iconName: 'bolt',
      specialEffect: 'adrenaline',
    ),
    AugmentData(
      id: 'master_of_arms',
      nameKey: 'augment_master_of_arms',
      descKey: 'augment_master_of_arms_desc',
      iconName: 'weapons',
      specialEffect: 'master_of_arms',
    ),
    AugmentData(
      id: 'double_trouble',
      nameKey: 'augment_double_trouble',
      descKey: 'augment_double_trouble_desc',
      iconName: 'twins',
      specialEffect: 'double_trouble',
    ),
    AugmentData(
      id: 'giant_slayer',
      nameKey: 'augment_giant_slayer',
      descKey: 'augment_giant_slayer_desc',
      iconName: 'giant',
      specialEffect: 'giant_slayer',
    ),

    // ===== Category 3: Status Synergies (5) =====
    AugmentData(
      id: 'toxic_explosion',
      nameKey: 'augment_toxic_explosion',
      descKey: 'augment_toxic_explosion_desc',
      iconName: 'toxic',
      specialEffect: 'toxic_explosion',
    ),
    AugmentData(
      id: 'combustion',
      nameKey: 'augment_combustion',
      descKey: 'augment_combustion_desc',
      iconName: 'fire_eternal',
      specialEffect: 'combustion',
    ),
    AugmentData(
      id: 'shatter_strike',
      nameKey: 'augment_shatter_strike',
      descKey: 'augment_shatter_strike_desc',
      iconName: 'ice_break',
      specialEffect: 'shatter_strike',
    ),
    AugmentData(
      id: 'bloodthirst',
      nameKey: 'augment_bloodthirst',
      descKey: 'augment_bloodthirst_desc',
      iconName: 'blood_drop',
      specialEffect: 'bloodthirst',
    ),
    AugmentData(
      id: 'exploit_weakness',
      nameKey: 'augment_exploit_weakness',
      descKey: 'augment_exploit_weakness_desc',
      iconName: 'weakness',
      statBonuses: {'knockback': 10.0},
      specialEffect: 'exploit_weakness',
    ),

    // ===== Category 4: Special Rules & Mechanics (5) =====
    AugmentData(
      id: 'ricochet',
      nameKey: 'augment_ricochet',
      descKey: 'augment_ricochet_desc',
      iconName: 'bounce',
      specialEffect: 'ricochet',
    ),
    AugmentData(
      id: 'sniper_focus',
      nameKey: 'augment_sniper_focus',
      descKey: 'augment_sniper_focus_desc',
      iconName: 'scope',
      specialEffect: 'sniper_focus',
    ),
    AugmentData(
      id: 'heavy_duty',
      nameKey: 'augment_heavy_duty',
      descKey: 'augment_heavy_duty_desc',
      iconName: 'quake',
      specialEffect: 'heavy_duty',
    ),
    AugmentData(
      id: 'overcrowded',
      nameKey: 'augment_overcrowded',
      descKey: 'augment_overcrowded_desc',
      iconName: 'crowd',
      specialEffect: 'overcrowded',
    ),
    AugmentData(
      id: 'last_stand',
      nameKey: 'augment_last_stand',
      descKey: 'augment_last_stand_desc',
      iconName: 'phoenix',
      specialEffect: 'last_stand',
    ),
  ];

  /// Pick N random augments (no duplicates with already chosen ones)
  static List<AugmentData> getChoices(
      {int count = 3, Set<String> excludeIds = const {}}) {
    final available =
        _allAugments.where((a) => !excludeIds.contains(a.id)).toList();
    available.shuffle(_random);
    return available.take(count).toList();
  }
}
