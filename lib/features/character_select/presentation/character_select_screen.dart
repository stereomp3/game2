import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../platform/android/fake_purchase_service.dart';
import '../../gameplay/application/game_session_provider.dart';

/// Character data definition (Pure Dart)
class CharacterData {
  final String id;
  final String nameKey;
  final String descKey;
  final String weaponNameKey;
  final bool isFree;
  final Color themeColor;
  final IconData iconPlaceholder;
  final Map<String, dynamic> baseStats;

  const CharacterData({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.weaponNameKey,
    required this.isFree,
    required this.themeColor,
    required this.iconPlaceholder,
    required this.baseStats,
  });
}

/// 5 playable characters
/// [Asset needed]: each character needs a portrait image
/// Asset path: assets/images/entities/{id}_portrait.png
const _characters = [
  CharacterData(
    id: 'novice',
    nameKey: 'char_novice',
    descKey: 'char_novice_desc',
    weaponNameKey: 'Longsword',
    isFree: true,
    themeColor: GameColors.accentGold,
    iconPlaceholder: Icons.person,
    baseStats: {
      'hp': 100, 'move_speed': 110, 'armor': 5,
      'melee_dmg': 10, 'ranged_dmg': 10, 'dodge': 5,
    },
  ),
  CharacterData(
    id: 'pyromaniac',
    nameKey: 'char_pyromaniac',
    descKey: 'char_pyromaniac_desc',
    weaponNameKey: 'Flamethrower',
    isFree: true,
    themeColor: GameColors.statusBurn,
    iconPlaceholder: Icons.local_fire_department,
    baseStats: {
      'hp': 90, 'move_speed': 105, 'armor': 3,
      'melee_dmg': 7, 'ranged_dmg': 7, 'elemental_dmg': 15, 'dodge': 5,
    },
  ),
  CharacterData(
    id: 'ninja',
    nameKey: 'char_ninja',
    descKey: 'char_ninja_desc',
    weaponNameKey: 'Dagger',
    isFree: false,
    themeColor: GameColors.accentCyan,
    iconPlaceholder: Icons.flash_on,
    baseStats: {
      'hp': 60, 'move_speed': 135, 'armor': 2,
      'melee_dmg': 12, 'crit_chance': 20, 'dodge': 30,
    },
  ),
  CharacterData(
    id: 'tank',
    nameKey: 'char_tank',
    descKey: 'char_tank_desc',
    weaponNameKey: 'Spiky Shield',
    isFree: false,
    themeColor: Colors.blueGrey,
    iconPlaceholder: Icons.shield,
    baseStats: {
      'hp': 180, 'move_speed': 80, 'armor': 20,
      'melee_dmg': 8, 'knockback_resist': 100, 'dodge': 0,
    },
  ),
  CharacterData(
    id: 'alchemist',
    nameKey: 'char_alchemist',
    descKey: 'char_alchemist_desc',
    weaponNameKey: 'Venom Slingshot',
    isFree: false,
    themeColor: GameColors.statusPoison,
    iconPlaceholder: Icons.science,
    baseStats: {
      'hp': 85, 'move_speed': 100, 'armor': 4,
      'elemental_dmg': 12, 'debuff_duration': 200, 'dodge': 5,
    },
  ),
];

/// Character selection screen
class CharacterSelectScreen extends ConsumerStatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  ConsumerState<CharacterSelectScreen> createState() =>
      _CharacterSelectScreenState();
}

class _CharacterSelectScreenState
    extends ConsumerState<CharacterSelectScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _detailController;
  late Animation<double> _detailFade;

  @override
  void initState() {
    super.initState();
    _detailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _detailFade = CurvedAnimation(
      parent: _detailController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _selectCharacter(int index) {
    if (index == _selectedIndex) return;
    _detailController.reset();
    setState(() => _selectedIndex = index);
    _detailController.forward();
  }

  CharacterData get _current => _characters[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final purchaseAsync = ref.watch(fakePurchaseProvider);
    final purchase = purchaseAsync.value ?? const FakePurchaseState();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(s),
              SizedBox(
                height: 120,
                child: _buildCharacterList(s, purchase),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FadeTransition(
                  opacity: _detailFade,
                  child: _buildCharacterDetail(s, purchase),
                ),
              ),
              _buildBottomAction(s, purchase),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          ),
          Text(
            s.t('select_character'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList(S s, FakePurchaseState purchase) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        final char = _characters[index];
        final isSelected = index == _selectedIndex;
        final isLocked = !char.isFree &&
            !purchase.unlockedCharacters.contains(char.id);

        return GestureDetector(
          onTap: () => _selectCharacter(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 90,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? char.themeColor.withValues(alpha: 0.2)
                  : GameColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? char.themeColor : Colors.white12,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(
                      color: char.themeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    )]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      char.iconPlaceholder,
                      color: isLocked ? Colors.white24 : char.themeColor,
                      size: 36,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.t(char.nameKey),
                      style: TextStyle(
                        color: isLocked ? Colors.white24 : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (isLocked)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.lock,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterDetail(S s, FakePurchaseState purchase) {
    final char = _current;
    final isLocked = !char.isFree &&
        !purchase.unlockedCharacters.contains(char.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Character portrait placeholder
          Container(
            width: 160,
            height: 200,
            decoration: BoxDecoration(
              color: char.themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: char.themeColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  char.iconPlaceholder,
                  color: isLocked ? Colors.white24 : char.themeColor,
                  size: 72,
                ),
                if (isLocked) ...[
                  const SizedBox(height: 8),
                  const Icon(Icons.lock, color: Colors.white38, size: 24),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.t(char.nameKey),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: char.themeColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.t(char.descKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            s.t('character_weapon'),
            char.weaponNameKey,
            Icons.gavel,
            char.themeColor,
          ),
          const SizedBox(height: 16),
          Text(
            s.t('character_stats'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...char.baseStats.entries.map((e) => _buildStatBar(
            s.t('stat_${e.key}'),
            e.value.toDouble(),
            e.key == 'hp' ? 200 : 150,
            char.themeColor,
          )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(
      String name, double value, double maxValue, Color color) {
    final ratio = (value / maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              name,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.6), color],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${value.toInt()}',
              textAlign: TextAlign.right,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(S s, FakePurchaseState purchase) {
    final char = _current;
    final isLocked = !char.isFree &&
        !purchase.unlockedCharacters.contains(char.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: isLocked
            ? _buildUnlockButton(s, char)
            : _buildSelectButton(s, char),
      ),
    );
  }

  Widget _buildSelectButton(S s, CharacterData char) {
    return ElevatedButton(
      onPressed: () {
        // Initialize new game session
        ref.read(gameSessionProvider.notifier).startNewRun(char.id);
        Navigator.pushNamed(
          context,
          AppRouter.gameplay,
          arguments: {'characterId': char.id, 'waveNumber': 1},
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: char.themeColor,
        foregroundColor: GameColors.backgroundDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        textStyle:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text(s.t('select')),
    );
  }

  Widget _buildUnlockButton(S s, CharacterData char) {
    final purchaseState =
        ref.watch(fakePurchaseProvider).value ?? const FakePurchaseState();

    return ElevatedButton.icon(
      onPressed: purchaseState.status == PurchaseStatus.idle
          ? () => _showPurchaseDialog(char)
          : null,
      icon: const Icon(Icons.lock_open),
      label: Text('${s.t("unlock")} - ${s.t("purchase_price")}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: GameColors.accentGold,
        foregroundColor: GameColors.backgroundDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showPurchaseDialog(CharacterData char) {
    final s = S(ref.read(localeProvider));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(builder: (context, ref, _) {
          final asyncState = ref.watch(fakePurchaseProvider);
          final state =
              asyncState.value ?? const FakePurchaseState();

          return AlertDialog(
            backgroundColor: GameColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              s.t('purchase_title'),
              style: const TextStyle(color: Colors.white),
            ),
            content: _buildPurchaseContent(s, state, char),
            actions: state.status == PurchaseStatus.idle
                ? [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(s.t('cancel'),
                          style:
                              const TextStyle(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(fakePurchaseProvider.notifier)
                            .startPurchase(char.id)
                            .then((_) {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameColors.accentGold,
                      ),
                      child: Text(
                        '${s.t("buy")} ${s.t("purchase_price")}',
                        style: const TextStyle(
                            color: GameColors.backgroundDark),
                      ),
                    ),
                  ]
                : null,
          );
        });
      },
    );
  }

  Widget _buildPurchaseContent(
      S s, FakePurchaseState state, CharacterData char) {
    switch (state.status) {
      case PurchaseStatus.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(char.iconPlaceholder,
                color: char.themeColor, size: 64),
            const SizedBox(height: 12),
            Text(
              s.t(char.nameKey),
              style: TextStyle(
                color: char.themeColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.t(char.descKey),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        );

      case PurchaseStatus.processing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation(GameColors.accentGold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.t('purchase_processing'),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        );

      case PurchaseStatus.success:
      case PurchaseStatus.unlocked:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: GameColors.accentGreen, size: 56),
            const SizedBox(height: 12),
            Text(
              s.t('purchase_success'),
              style: const TextStyle(
                color: GameColors.accentGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
    }
  }
}
