import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../progression/application/achievement_provider.dart';
import '../../progression/domain/achievement_system.dart';
import '../application/game_session_provider.dart';
import '../domain/weapon_system.dart';
import 'achievement_toast.dart';

/// Game over summary screen - shows stats from the completed run
class GameOverScreen extends ConsumerStatefulWidget {
  final int waveReached;
  final int totalKills;
  final int levelReached;

  const GameOverScreen({
    super.key,
    required this.waveReached,
    required this.totalKills,
    this.levelReached = 1,
  });

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  List<AchievementDef> _newAchievements = [];
  int _toastIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideUp = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    );

    // Record run to achievement system
    _recordAchievements();
  }

  void _recordAchievements() {
    final session = ref.read(gameSessionProvider);
    ref.read(achievementProvider.notifier).recordRunEnd(
      kills: widget.totalKills,
      goldEarned: session.gold,
      wavesCleared: widget.waveReached,
      highestWave: widget.waveReached,
      merges: 0, // TODO: track merges in session
      augmentsChosen: session.chosenAugments.length,
    );

    // Check for newly unlocked achievements after a frame
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final newlyUnlocked =
          ref.read(achievementProvider.notifier).popNewlyUnlocked();
      if (newlyUnlocked.isNotEmpty) {
        setState(() => _newAchievements = newlyUnlocked);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final session = ref.read(gameSessionProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0A1A), Color(0xFF1A0A0A)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Skull icon
                    FadeTransition(
                      opacity: _fadeIn,
                      child: const Icon(
                        Icons.sentiment_dissatisfied,
                        color: GameColors.accentRed,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Game Over text
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Text(
                        s.t('game_over'),
                        style: const TextStyle(
                          color: GameColors.accentRed,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Stats card
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(_slideUp),
                      child: FadeTransition(
                        opacity: _slideUp,
                        child: _buildStatsCard(s, session),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Augments display
                    if (session.chosenAugments.isNotEmpty) ...[
                      FadeTransition(
                        opacity: _slideUp,
                        child: _buildAugmentsSummary(s, session),
                      ),
                      const SizedBox(height: 32),
                    ],
                    // Return button
                    FadeTransition(
                      opacity: _slideUp,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context, AppRouter.startScreen, (_) => false),
                        icon: const Icon(Icons.home),
                        label: Text(s.t('return_to_menu')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameColors.accentGold,
                          foregroundColor: GameColors.backgroundDark,
                          minimumSize: const Size(220, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Achievement unlock toasts
          if (_toastIndex < _newAchievements.length)
            AchievementToast(
              key: ValueKey(_toastIndex),
              achievement: _newAchievements[_toastIndex],
              locale: locale,
              onDismiss: () {
                if (mounted) {
                  setState(() => _toastIndex++);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(S s, GameSessionState session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _statRow(
            Icons.waves,
            s.t('wave', {'n': '${widget.waveReached}'}),
            GameColors.accentCyan,
          ),
          const SizedBox(height: 16),
          _statRow(
            Icons.star,
            '${widget.totalKills} ${s.t("stat_melee_dmg").split(" ").first}',
            GameColors.accentGold,
            subtitle: 'Kills',
          ),
          const SizedBox(height: 16),
          _statRow(
            Icons.monetization_on,
            '${session.gold} G',
            GameColors.accentGold,
            subtitle: s.t('gold'),
          ),
          const SizedBox(height: 16),
          _statRow(
            Icons.inventory,
            '${session.inventory.usedSlots} / ${InventorySystem.maxSlots}',
            Colors.white54,
            subtitle: s.t('shop'),
          ),
          if (widget.levelReached > 1) ...[
            const SizedBox(height: 16),
            _statRow(
              Icons.arrow_upward,
              'Lv.${widget.levelReached}',
              GameColors.accentCyan,
              subtitle: 'Level',
            ),
          ],
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String value, Color color,
      {String? subtitle}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAugmentsSummary(S s, GameSessionState session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            s.t('augment_title'),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: session.chosenAugments
                .map((a) => Chip(
                      label: Text(s.t(a.nameKey)),
                      backgroundColor:
                          GameColors.accentGold.withValues(alpha: 0.15),
                      labelStyle: const TextStyle(
                        color: GameColors.accentGold,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                          color: GameColors.accentGold.withValues(alpha: 0.3)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
