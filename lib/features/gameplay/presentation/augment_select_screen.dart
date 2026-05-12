import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../application/game_session_provider.dart';
import '../domain/augment_system.dart';

/// Augment selection screen - appears every 3 waves
/// Player picks 1 of 3 random augments as a permanent buff
class AugmentSelectScreen extends ConsumerStatefulWidget {
  const AugmentSelectScreen({super.key});

  @override
  ConsumerState<AugmentSelectScreen> createState() =>
      _AugmentSelectScreenState();
}

class _AugmentSelectScreenState extends ConsumerState<AugmentSelectScreen>
    with SingleTickerProviderStateMixin {
  late List<AugmentData> _choices;
  int? _selectedIndex;
  late AnimationController _enterController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    final session = ref.read(gameSessionProvider);
    _choices = AugmentDatabase.getChoices(
      count: 3,
      excludeIds: session.chosenAugmentIds,
    );

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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

  void _selectAugment(int index) {
    setState(() => _selectedIndex = index);
  }

  void _confirmSelection() {
    if (_selectedIndex == null) return;
    final chosen = _choices[_selectedIndex!];
    ref.read(gameSessionProvider.notifier).chooseAugment(chosen);

    final session = ref.read(gameSessionProvider);
    Navigator.pushReplacementNamed(
      context,
      AppRouter.gameplay,
      arguments: {
        'characterId': session.characterId,
        'waveNumber': session.currentWave,
      },
    );
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
            colors: [Color(0xFF0A0E2A), Color(0xFF1A1040)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Title
                _buildTitle(s),
                const SizedBox(height: 12),
                Text(
                  s.t('augment_subtitle'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                // Augment cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(
                        _choices.length,
                        (i) => Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: _buildAugmentCard(s, i),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Confirm button
                _buildConfirmButton(s),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(S s) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [GameColors.accentGold, GameColors.accentCyan],
      ).createShader(bounds),
      child: Text(
        s.t('augment_title'),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAugmentCard(S s, int index) {
    final augment = _choices[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _selectAugment(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isSelected
                ? [
                    GameColors.accentGold.withValues(alpha: 0.2),
                    GameColors.accentGold.withValues(alpha: 0.05),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? GameColors.accentGold
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GameColors.accentGold.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? GameColors.accentGold.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isSelected
                        ? GameColors.accentGold.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  _getAugmentIcon(augment.iconName),
                  color:
                      isSelected ? GameColors.accentGold : Colors.white54,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                s.t(augment.nameKey),
                style: TextStyle(
                  color: isSelected
                      ? GameColors.accentGold
                      : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                s.t(augment.descKey),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Stat bonuses
              ...augment.statBonuses.entries.take(3).map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward,
                              color: GameColors.accentGreen, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '+${e.value < 1 ? e.value.toStringAsFixed(2) : e.value.toStringAsFixed(0)} ${s.t("stat_${e.key}")}',
                            style: const TextStyle(
                              color: GameColors.accentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _selectedIndex != null ? _confirmSelection : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.accentGold,
            foregroundColor: GameColors.backgroundDark,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
            disabledForegroundColor: Colors.white24,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: Text(s.t('confirm')),
        ),
      ),
    );
  }

  IconData _getAugmentIcon(String iconName) {
    switch (iconName) {
      case 'sword':
        return Icons.gavel;
      case 'target':
        return Icons.gps_fixed;
      case 'fire':
        return Icons.local_fire_department;
      case 'skull':
        return Icons.dangerous;
      case 'shield':
        return Icons.shield;
      case 'heart':
        return Icons.favorite;
      case 'ghost':
        return Icons.blur_on;
      case 'castle':
        return Icons.castle;
      case 'coin':
        return Icons.monetization_on;
      case 'potion':
        return Icons.science;
      case 'clock':
        return Icons.timer;
      case 'blood':
        return Icons.water_drop;
      default:
        return Icons.star;
    }
  }
}
