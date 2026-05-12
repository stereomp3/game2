import 'dart:math';
import '../../../core/data/data_manager.dart';

/// Weapon rarity tiers
enum WeaponQuality {
  normal,    // White - Common
  fine,      // Blue - Fine
  excellent, // Purple - Excellent
  legendary, // Red - Legendary
}

/// Equipment Type
enum EquipmentType { weapon, item, ability }

/// Weapon/Item data definition (Pure Dart, data-driven)
class WeaponData {
  final String id;
  final EquipmentType type;
  final double baseCooldown;
  final String nameKey;
  final String descKey;
  final WeaponQuality quality;
  final int buyCost;
  final int sellValue;
  final bool isRanged;
  final Map<String, double> statBonuses;
  final String? specialEffectKey;

  const WeaponData({
    required this.id,
    this.type = EquipmentType.weapon,
    this.baseCooldown = 1.0,
    required this.nameKey,
    required this.descKey,
    this.quality = WeaponQuality.normal,
    required this.buyCost,
    required this.sellValue,
    this.isRanged = false,
    this.statBonuses = const {},
    this.specialEffectKey,
  });

  String get baseId {
    if (id.contains('_w')) return id.split('_w')[0];
    if (id.contains('_upgraded')) return id.split('_upgraded')[0];
    return id;
  }

  /// Create upgraded version (merge result)
  WeaponData upgrade() {
    final nextQuality = WeaponQuality.values[
        (quality.index + 1).clamp(0, WeaponQuality.values.length - 1)];
    final multiplier = 1.5;
    return WeaponData(
      id: '${id}_upgraded',
      type: type,
      baseCooldown: baseCooldown * 0.9, // Slightly faster attack on upgrade
      nameKey: nameKey,
      descKey: descKey,
      quality: nextQuality,
      buyCost: (buyCost * 2).toInt(),
      sellValue: (sellValue * 2).toInt(),
      isRanged: isRanged,
      statBonuses: statBonuses.map(
          (key, value) => MapEntry(key, (value * multiplier))),
      specialEffectKey: specialEffectKey,
    );
  }
}

/// Player inventory system
/// Manages weapon slots with merge/combine mechanics
class InventorySystem {
  static const maxSlots = 6;
  final List<WeaponData?> _slots = List.filled(maxSlots, null); // Only for weapons
  final List<WeaponData> _items = [];
  final List<WeaponData> _abilities = [];
  int _gold = 0;

  List<WeaponData?> get slots => List.unmodifiable(_slots);
  List<WeaponData> get items => List.unmodifiable(_items);
  List<WeaponData> get abilities => List.unmodifiable(_abilities);
  int get gold => _gold;
  
  int get usedSlots => _slots.where((s) => s != null).length;
  bool get isFull => usedSlots >= maxSlots; // Only applies to weapons

  void setGold(int amount) => _gold = amount;
  void addGold(int amount) => _gold += amount;

  /// Try to add equipment to inventory
  bool addWeapon(WeaponData equipment) {
    if (equipment.type == EquipmentType.item) {
      _items.add(equipment);
      return true;
    } else if (equipment.type == EquipmentType.ability) {
      _abilities.add(equipment);
      return true;
    }

    // Weapons go to slots
    for (int i = 0; i < maxSlots; i++) {
      if (_slots[i] == null) {
        _slots[i] = equipment;
        return true;
      }
    }
    return false; // Weapon inventory full
  }

  /// Remove weapon from slot
  WeaponData? removeWeapon(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= maxSlots) return null;
    final weapon = _slots[slotIndex];
    _slots[slotIndex] = null;
    return weapon;
  }

  /// Sell weapon from slot, returns gold earned
  int sellWeapon(int slotIndex) {
    final weapon = _slots[slotIndex];
    if (weapon == null) return 0;
    _slots[slotIndex] = null;
    _gold += weapon.sellValue;
    return weapon.sellValue;
  }

  /// Sell item or ability
  int sellItem(WeaponData item) {
    if (_items.remove(item)) {
      _gold += item.sellValue;
      return item.sellValue;
    }
    if (_abilities.remove(item)) {
      _gold += item.sellValue;
      return item.sellValue;
    }
    return 0;
  }

  /// Try to merge two weapons of same type and quality
  WeaponData? tryMerge(int slotA, int slotB) {
    if (slotA == slotB) return null;
    final weaponA = _slots[slotA];
    final weaponB = _slots[slotB];
    if (weaponA == null || weaponB == null) return null;

    if (weaponA.type != EquipmentType.weapon) return null; // Only weapons merge

    if (weaponA.nameKey != weaponB.nameKey) return null;
    if (weaponA.quality != weaponB.quality) return null;
    if (weaponA.quality == WeaponQuality.legendary) return null; // Max tier

    final merged = weaponA.upgrade();
    _slots[slotA] = merged;
    _slots[slotB] = null;
    return merged;
  }

  /// Buy equipment from shop
  bool buyWeapon(WeaponData equipment) {
    if (_gold < equipment.buyCost) return false;
    if (equipment.type == EquipmentType.weapon && isFull) return false;
    _gold -= equipment.buyCost;
    return addWeapon(equipment);
  }

  /// Calculate total stat bonuses from all equipped weapons, items, and abilities
  Map<String, double> getTotalBonuses() {
    final totals = <String, double>{};
    
    void addBonuses(WeaponData? equip) {
      if (equip == null) return;
      equip.statBonuses.forEach((key, value) {
        totals[key] = (totals[key] ?? 0) + value;
      });
    }

    for (final w in _slots) { addBonuses(w); }
    for (final i in _items) { addBonuses(i); }
    for (final a in _abilities) { addBonuses(a); }

    return totals;
  }
}

/// Weapon database - all available weapons
class WeaponDatabase {
  static final _random = Random();

  /// Generate shop items based on wave and luck
  static List<WeaponData> generateShopItems(int waveNumber,
      {double luck = 0, int count = 6}) {
    final baseWeapons = DataManager.weapons;
    final items = <WeaponData>[];
    for (int i = 0; i < count; i++) {
      // Pick random base weapon
      final base = baseWeapons[_random.nextInt(baseWeapons.length)];

      // Determine quality based on wave + luck
      final qualityRoll = _random.nextDouble() + luck * 0.01;
      WeaponQuality quality;
      if (qualityRoll > 0.95 && waveNumber > 8) {
        quality = WeaponQuality.legendary;
      } else if (qualityRoll > 0.75 && waveNumber > 4) {
        quality = WeaponQuality.excellent;
      } else if (qualityRoll > 0.45 && waveNumber > 2) {
        quality = WeaponQuality.fine;
      } else {
        quality = WeaponQuality.normal;
      }

      // Scale stats and cost by quality
      final qualityMultiplier = 1.0 + quality.index * 0.5;
      final costMultiplier = 1.0 + quality.index * 0.8;
      final waveScale = 1.0 + waveNumber * 0.1;

      items.add(WeaponData(
        id: '${base.id}_w${waveNumber}_$i',
        type: base.type,
        nameKey: base.nameKey,
        descKey: base.descKey,
        quality: quality,
        buyCost: (base.buyCost * costMultiplier * waveScale).toInt(),
        sellValue: (base.sellValue * costMultiplier * waveScale * 0.5).toInt(),
        isRanged: base.isRanged,
        statBonuses: base.statBonuses.map(
            (k, v) => MapEntry(k, v * qualityMultiplier * waveScale)),
        specialEffectKey: base.specialEffectKey,
      ));
    }
    return items;
  }
}
