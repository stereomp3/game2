import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../gameplay/application/game_session_provider.dart';
import '../../gameplay/domain/weapon_system.dart';

/// Shop screen - appears between waves
/// Integrates WeaponDatabase for item generation, inventory display, and merge
class ShopScreen extends ConsumerStatefulWidget {
  final int waveNumber;
  final int goldAmount;
  final String characterId;

  const ShopScreen({
    super.key,
    required this.waveNumber,
    required this.goldAmount,
    this.characterId = 'novice',
  });

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  late int _gold;
  late List<WeaponData> _shopItems;
  late List<bool> _soldFlags;
  int? _mergeSourceSlot;

  late AnimationController _enterController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _gold = widget.goldAmount;

    // Sync gold to session safely after build phase
    Future.microtask(() {
      final session = ref.read(gameSessionProvider.notifier);
      final currentGold = ref.read(gameSessionProvider).gold;
      if (widget.goldAmount > currentGold) {
        session.earnGold(widget.goldAmount - currentGold);
      }
    });

    // Generate items from WeaponDatabase
    _shopItems = WeaponDatabase.generateShopItems(widget.waveNumber);
    _soldFlags = List.filled(_shopItems.length, false);

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  InventorySystem get _inventory =>
      ref.read(gameSessionProvider.notifier).inventory;

  void _buyItem(int index) {
    if (_soldFlags[index]) return;
    final weapon = _shopItems[index];
    if (_gold < weapon.buyCost) return;
    if (_inventory.isFull) return;

    setState(() {
      _gold -= weapon.buyCost;
      _soldFlags[index] = true;
      _inventory.addWeapon(weapon);
      ref.read(gameSessionProvider.notifier).spendGold(weapon.buyCost);
    });
  }

  void _sellItem(int slotIndex) {
    final goldEarned = _inventory.sellWeapon(slotIndex);
    if (goldEarned > 0) {
      setState(() {
        _gold += goldEarned;
        ref.read(gameSessionProvider.notifier).earnGold(goldEarned);
      });
    }
  }

  void _tryMerge(int slotIndex) {
    if (_mergeSourceSlot == null) {
      setState(() => _mergeSourceSlot = slotIndex);
      return;
    }

    if (_mergeSourceSlot == slotIndex) {
      setState(() => _mergeSourceSlot = null);
      return;
    }

    final result = _inventory.tryMerge(_mergeSourceSlot!, slotIndex);
    setState(() {
      _mergeSourceSlot = null;
      if (result != null) {
        // Merge succeeded - UI will refresh from inventory
      }
    });
  }

  void _reroll() {
    if (_gold < GameConstants.shopRerollCost) return;
    setState(() {
      _gold -= GameConstants.shopRerollCost;
      ref.read(gameSessionProvider.notifier).spendGold(GameConstants.shopRerollCost);
      _shopItems = WeaponDatabase.generateShopItems(widget.waveNumber);
      _soldFlags = List.filled(_shopItems.length, false);
    });
  }

  void _nextWave() {
    final session = ref.read(gameSessionProvider.notifier);
    session.advanceWave();
    final nextWave = ref.read(gameSessionProvider).currentWave;

    // Every 3 waves show augment selection
    if (nextWave % 3 == 1 && nextWave > 1) {
      Navigator.pushReplacementNamed(context, AppRouter.augmentSelect);
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRouter.gameplay,
        arguments: {
          'characterId': widget.characterId,
          'waveNumber': nextWave,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                _buildHeader(s),
                const SizedBox(height: 12),
                // Shop items
                SizedBox(
                  height: 190,
                  child: _buildShopRow(s),
                ),
                const SizedBox(height: 12),
                // Inventory section header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${s.t("shop")} - ${_inventory.usedSlots}/${InventorySystem.maxSlots} ${s.t("weapon")}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_mergeSourceSlot != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: GameColors.accentCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'MERGE MODE',
                            style: TextStyle(
                              color: GameColors.accentCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Categorized Inventory Lists
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildWeaponGrid(s),
                      const SizedBox(height: 16),
                      _buildSectionHeader('Items', Icons.backpack),
                      const SizedBox(height: 8),
                      _buildOtherEquipmentGrid(s, _inventory.items),
                      const SizedBox(height: 16),
                      _buildSectionHeader('Abilities', Icons.star),
                      const SizedBox(height: 8),
                      _buildOtherEquipmentGrid(s, _inventory.abilities),
                    ],
                  ),
                ),
                _buildBottomBar(s),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            s.t('shop_title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              s.t('wave', {'n': '${widget.waveNumber}'}),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          const Spacer(),
          _buildGoldBadge(),
        ],
      ),
    );
  }

  Widget _buildGoldBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: GameColors.accentGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: GameColors.accentGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on,
              color: GameColors.accentGold, size: 20),
          const SizedBox(width: 6),
          Text(
            '$_gold',
            style: const TextStyle(
              color: GameColors.accentGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopRow(S s) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _shopItems.length,
      itemBuilder: (context, index) => _buildShopCard(s, index),
    );
  }

  Widget _buildShopCard(S s, int index) {
    final weapon = _shopItems[index];
    final isSold = _soldFlags[index];
    final canAfford = _gold >= weapon.buyCost;
    final qualityColor = GameColors.getQualityColor(weapon.quality.index);

    return GestureDetector(
      onTap: () => _buyItem(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130, // Scale down the item boxes
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSold
              ? Colors.white.withValues(alpha: 0.03)
              : GameColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSold
                ? Colors.white10
                : qualityColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: isSold
              ? []
              : [
                  BoxShadow(
                    color: qualityColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quality badge & Type badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: qualityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.t(_getQualityKey(weapon.quality.index)),
                      style: TextStyle(
                        color: qualityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      weapon.type.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Weapon icon
              Center(
                child: Image.asset(
                  'assets/images/weapons/${weapon.baseId}.png',
                  width: 36,
                  height: 36,
                  filterQuality: FilterQuality.none, // Pixel art style
                  color: isSold ? Colors.black54 : null, // Dim when sold
                  colorBlendMode: isSold ? BlendMode.srcATop : null,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      _getWeaponIcon(weapon.id),
                      color: isSold ? Colors.white12 : qualityColor,
                      size: 36,
                    );
                  },
                ),
              ),
              const Spacer(),
              // Name
              Text(
                s.t(weapon.nameKey),
                style: TextStyle(
                  color: isSold ? Colors.white24 : Colors.white,
                  fontSize: 11, // Smaller text
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Stats
              ...weapon.statBonuses.entries.take(2).map(
                    (e) => Text(
                      '+${e.value < 1 ? e.value.toStringAsFixed(2) : e.value.toStringAsFixed(0)} ${s.t("stat_${e.key}")}',
                      style: TextStyle(
                        color: isSold ? Colors.white12 : Colors.white38,
                        fontSize: 9, // Smaller text
                      ),
                    ),
                  ),
              const Spacer(),
              // Price
              isSold
                  ? Text(s.t('sold_out'),
                      style:
                          const TextStyle(color: Colors.white24, fontSize: 11))
                  : Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            color: GameColors.accentGold, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${weapon.buyCost}',
                          style: TextStyle(
                            color: canAfford
                                ? GameColors.accentGold
                                : GameColors.accentRed,
                            fontSize: 12, // Smaller price text
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeaponGrid(S s) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130, // Scale down max width
        childAspectRatio: 0.75, // Adjust for new dimensions
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: InventorySystem.maxSlots,
      itemBuilder: (context, index) => _buildInventorySlot(s, index),
    );
  }

  Widget _buildOtherEquipmentGrid(S s, List<WeaponData> equipments) {
    if (equipments.isEmpty) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 130,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 1, // Show at least one empty slot placeholder
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white12, size: 24),
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130, // Scale down max width
        childAspectRatio: 0.75, // Adjust for new dimensions
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: equipments.length,
      itemBuilder: (context, index) => _buildEquipmentSlot(s, equipments[index]),
    );
  }

  Widget _buildInventorySlot(S s, int index) {
    final weapon = _inventory.slots[index];
    final isSelected = _mergeSourceSlot == index;

    if (weapon == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white12, size: 24),
        ),
      );
    }

    final qualityColor = GameColors.getQualityColor(weapon.quality.index);

    return GestureDetector(
      onTap: () => _tryMerge(index),
      onLongPress: () => _showItemActions(s, index, weapon),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? GameColors.accentCyan.withValues(alpha: 0.15)
              : GameColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? GameColors.accentCyan
                : qualityColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GameColors.accentCyan.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Quality dot
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: qualityColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${weapon.sellValue}G',
                    style: const TextStyle(
                        color: Colors.white24, fontSize: 9),
                  ),
                ],
              ),
              const Spacer(),
              Image.asset(
                'assets/images/weapons/${weapon.baseId}.png',
                width: 28,
                height: 28,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _getWeaponIcon(weapon.id),
                    color: qualityColor,
                    size: 28,
                  );
                },
              ),
              const Spacer(),
              Text(
                s.t(weapon.nameKey),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemActions(S s, int index, WeaponData weapon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.t(weapon.nameKey),
              style: TextStyle(
                color: GameColors.getQualityColor(weapon.quality.index),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.t(weapon.descKey),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...weapon.statBonuses.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward,
                        color: GameColors.accentGreen, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+${e.value < 1 ? e.value.toStringAsFixed(2) : e.value.toStringAsFixed(0)} ${s.t("stat_${e.key}")}',
                      style: const TextStyle(
                        color: GameColors.accentGreen,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (weapon.type == EquipmentType.weapon) {
                      _sellItem(index);
                    } else {
                      setState(() {
                        final goldEarned = _inventory.sellItem(weapon);
                        _gold += goldEarned;
                        ref.read(gameSessionProvider.notifier).earnGold(goldEarned);
                      });
                    }
                  },
                  icon: const Icon(Icons.sell, size: 16),
                  label: Text('${s.t("sell")} (${weapon.sellValue}G)'),
                  style: TextButton.styleFrom(
                    foregroundColor: GameColors.accentGold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.t('close'),
                      style: const TextStyle(color: Colors.white38)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _gold >= GameConstants.shopRerollCost ? _reroll : null,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('${s.t("reroll")} (${GameConstants.shopRerollCost}G)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _nextWave,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(s.t('next_wave')),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.accentGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSlot(S s, WeaponData weapon) {
    final qualityColor = GameColors.getQualityColor(weapon.quality.index);

    return GestureDetector(
      onLongPress: () => _showItemActions(s, -1, weapon),
      child: Container(
        decoration: BoxDecoration(
          color: GameColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: qualityColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: qualityColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${weapon.sellValue}G',
                    style: const TextStyle(color: Colors.white24, fontSize: 9),
                  ),
                ],
              ),
              const Spacer(),
              Image.asset(
                'assets/images/weapons/${weapon.baseId}.png',
                width: 28,
                height: 28,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _getWeaponIcon(weapon.id),
                    color: qualityColor,
                    size: 28,
                  );
                },
              ),
              const Spacer(),
              Text(
                s.t(weapon.nameKey),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getQualityKey(int quality) {
    switch (quality) {
      case 0: return 'quality_normal';
      case 1: return 'quality_fine';
      case 2: return 'quality_excellent';
      case 3: return 'quality_legendary';
      default: return 'quality_normal';
    }
  }

  IconData _getWeaponIcon(String id) {
    if (id.contains('sword') || id.contains('dagger') || id.contains('scythe')) return Icons.hardware;
    if (id.contains('shield') || id.contains('plate')) return Icons.shield;
    if (id.contains('boots')) return Icons.directions_run;
    if (id.contains('bow') || id.contains('crossbow')) return Icons.gps_fixed;
    if (id.contains('pistol') || id.contains('shotgun')) return Icons.looks;
    if (id.contains('staff') || id.contains('fire') || id.contains('gasoline')) return Icons.local_fire_department;
    if (id.contains('ring') || id.contains('crit')) return Icons.radio_button_checked;
    if (id.contains('amulet') || id.contains('apple') || id.contains('medkit')) return Icons.favorite;
    if (id.contains('poison') || id.contains('venom') || id.contains('acid')) return Icons.science;
    if (id.contains('lightning') || id.contains('coffee')) return Icons.bolt;
    if (id.contains('frost') || id.contains('ice')) return Icons.ac_unit;
    if (id.contains('wrench')) return Icons.build;
    if (id.contains('scissors')) return Icons.content_cut;
    if (id.contains('hammer')) return Icons.gavel;
    if (id.contains('boomerang')) return Icons.all_out;
    if (id.contains('book')) return Icons.menu_book;
    if (id.contains('grenade')) return Icons.brightness_high;
    if (id.contains('cacti') || id.contains('spiked')) return Icons.eco;
    if (id.contains('orb') || id.contains('magic')) return Icons.blur_on;
    if (id.contains('telescope') || id.contains('scanner')) return Icons.search;
    if (id.contains('magnet')) return Icons.animation;
    if (id.contains('megaphone')) return Icons.campaign;
    if (id.contains('magnifier')) return Icons.zoom_in;
    if (id.contains('feather')) return Icons.air;
    if (id.contains('watch')) return Icons.access_time;
    if (id.contains('clover') || id.contains('luck')) return Icons.stars;
    if (id.contains('fang')) return Icons.coronavirus;
    
    return Icons.inventory;
  }
}
