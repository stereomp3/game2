import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/gameplay/domain/weapon_system.dart';
import '../../features/gameplay/domain/attribute_system.dart';
import '../constants/game_constants.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  static late final Map<String, dynamic> constants;
  static late final List<WeaponData> weapons;
  static late final Map<String, EntityStats> characters;
  static late final Map<String, Map<String, dynamic>> enemies;

  static Future<void> init() async {
    // 1. Load Constants
    final constantsStr = await rootBundle.loadString('assets/data/constants.json');
    constants = jsonDecode(constantsStr);
    GameConstants.init(constants);

    // 2. Load Weapons
    final weaponsStr = await rootBundle.loadString('assets/data/weapons.json');
    final weaponsJson = jsonDecode(weaponsStr)['weapons'] as List;
    weapons = weaponsJson.map((w) {
      final statBonusesJson = w['stat_bonuses'] as Map<String, dynamic>?;
      final statBonuses = <String, double>{};
      if (statBonusesJson != null) {
        statBonusesJson.forEach((k, v) => statBonuses[k] = (v as num).toDouble());
      }
      final typeStr = w['type'] as String? ?? 'weapon';
      EquipmentType type;
      switch (typeStr) {
        case 'item':
          type = EquipmentType.item;
          break;
        case 'ability':
          type = EquipmentType.ability;
          break;
        case 'weapon':
        default:
          type = EquipmentType.weapon;
      }

      return WeaponData(
        id: w['id'],
        type: type,
        baseCooldown: (w['base_cooldown'] as num?)?.toDouble() ?? 1.0,
        nameKey: w['name_key'],
        descKey: w['desc_key'],
        buyCost: w['buy_cost'],
        sellValue: w['sell_value'],
        isRanged: w['is_ranged'] ?? false,
        statBonuses: statBonuses,
        specialEffectKey: w['special_effect_key'],
      );
    }).toList();

    // 3. Load Characters
    final charsStr = await rootBundle.loadString('assets/data/characters.json');
    final charsJson = jsonDecode(charsStr)['characters'] as List;
    characters = {};
    for (final char in charsJson) {
      final statsJson = char['base_stats'] as Map<String, dynamic>;
      characters[char['id']] = EntityStats(
        maxHp: (statsJson['max_hp'] as num).toDouble(),
        hpRegen: (statsJson['hp_regen'] as num).toDouble(),
        lifesteal: (statsJson['lifesteal'] as num).toDouble() / 100.0,
        armor: (statsJson['armor'] as num).toDouble() / 100.0,
        dodge: (statsJson['dodge'] as num).toDouble() / 100.0,
        moveSpeed: (statsJson['move_speed'] as num).toDouble(),
        meleeDmg: (statsJson['melee_dmg'] as num).toDouble(),
        rangedDmg: (statsJson['ranged_dmg'] as num).toDouble(),
        elementalDmg: (statsJson['elemental_dmg'] as num).toDouble(),
        attackSpeed: (statsJson['attack_speed'] as num).toDouble(),
        critChance: (statsJson['crit_chance'] as num).toDouble() / 100.0,
        critDamage: (statsJson['crit_damage'] as num).toDouble() / 100.0,
        range: (statsJson['range'] as num).toDouble(),
        knockback: (statsJson['knockback'] as num).toDouble(),
        cooldownReduction: (statsJson['cooldown_reduction'] as num).toDouble() / 100.0,
        pickupRadius: (statsJson['pickup_radius'] as num).toDouble(),
        luck: (statsJson['luck'] as num).toDouble(),
        debuffDuration: (statsJson['debuff_duration'] as num).toDouble() / 100.0,
        statusEffectiveness: (statsJson['status_effectiveness'] as num).toDouble() / 100.0,
      );
    }

    // 4. Load Enemies
    final enemiesStr = await rootBundle.loadString('assets/data/enemies.json');
    final enemiesJson = jsonDecode(enemiesStr)['enemies'] as List;
    enemies = {};
    for (final enemy in enemiesJson) {
      enemies[enemy['id']] = enemy as Map<String, dynamic>;
    }
  }

  static EntityStats getEnemyBaseStats(String id) {
    final data = enemies[id]!;
    return EntityStats(
      maxHp: (data['max_hp'] as num).toDouble(),
      armor: (data['armor'] as num).toDouble(),
      moveSpeed: (data['move_speed'] as num).toDouble(),
      meleeDmg: (data['melee_dmg'] as num).toDouble(),
      rangedDmg: (data['ranged_dmg'] as num).toDouble(),
      attackSpeed: (data['attack_speed'] as num).toDouble(),
    );
  }
}
