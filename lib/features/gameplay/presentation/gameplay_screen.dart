import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/events/event_bus.dart';
import '../../../core/router/app_router.dart';
import '../application/game_session_provider.dart';
import '../infrastructure/survival_game_world.dart';
import 'tutorial_overlay.dart';

/// Gameplay screen - Flame GameWidget + Flutter HUD overlay
class GameplayScreen extends ConsumerStatefulWidget {
  final String characterId;
  final int waveNumber;

  const GameplayScreen({
    super.key,
    required this.characterId,
    this.waveNumber = 1,
  });

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen>
    with TickerProviderStateMixin {
  late SurvivalGameWorld _gameWorld;
  final EventBus _eventBus = EventBus();

  double _remainingTime = GameConstants.waveDurationSeconds;
  double _playerHpRatio = 1.0;
  bool _isPaused = false;
  bool _isGameOver = false;
  bool _showTutorial = false;

  late AnimationController _hudRefreshController;

  @override
  void initState() {
    super.initState();

    // Compute total bonus stats from inventory + augments
    final session = ref.read(gameSessionProvider);
    final inventoryBonuses = session.inventory.getTotalBonuses();
    final augmentBonuses = <String, double>{};
    for (final augment in session.chosenAugments) {
      augment.statBonuses.forEach((key, value) {
        augmentBonuses[key] = (augmentBonuses[key] ?? 0) + value;
      });
    }
    // Merge both bonus maps
    final totalBonuses = <String, double>{};
    for (final key in {...inventoryBonuses.keys, ...augmentBonuses.keys}) {
      totalBonuses[key] =
          (inventoryBonuses[key] ?? 0) + (augmentBonuses[key] ?? 0);
    }

    _gameWorld = SurvivalGameWorld(
      characterId: widget.characterId,
      waveNumber: widget.waveNumber,
      eventBus: _eventBus,
      bonusStatMap: totalBonuses,
      equippedWeapons: session.inventory.slots,
      equippedItems: session.inventory.items,
    );

    _eventBus.on<WaveEndEvent>((event) {
      if (!mounted) return;
      // Sync kills and gold to session
      ref.read(gameSessionProvider.notifier).completeWave(
            event.goldEarned + widget.waveNumber * 5,
            _gameWorld.enemiesKilled,
          );
      final updatedSession = ref.read(gameSessionProvider);
      Navigator.pushReplacementNamed(
        context,
        AppRouter.shop,
        arguments: {
          'waveNumber': widget.waveNumber,
          'gold': updatedSession.gold,
          'characterId': widget.characterId,
        },
      );
    });

    _eventBus.on<PlayerDeathEvent>((event) {
      if (!mounted) return;
      setState(() => _isGameOver = true);
      // Delay then navigate to game over screen
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRouter.gameOver,
          arguments: {
            'waveReached': widget.waveNumber,
            'totalKills': _gameWorld.enemiesKilled,
            'levelReached': _gameWorld.currentLevel,
          },
        );
      });
    });

    _hudRefreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
    _hudRefreshController.addListener(_refreshHUD);

    // Check if tutorial should show (first-time only)
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    if (widget.waveNumber == 1) {
      final shouldShow = await TutorialOverlay.shouldShow();
      if (shouldShow && mounted) {
        _gameWorld.pauseEngine();
        setState(() => _showTutorial = true);
      }
    }
  }

  void _refreshHUD() {
    if (!mounted) return;
    setState(() {
      _remainingTime = _gameWorld.remainingTime;
      _playerHpRatio = _gameWorld.playerHpRatio;
    });
  }

  @override
  void dispose() {
    _hudRefreshController.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _gameWorld.pauseEngine();
    } else {
      _gameWorld.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _gameWorld),
          SafeArea(
            child: Stack(
              children: [
                _buildTopHUD(s),
                Positioned(
                  top: 8,
                  right: 16,
                  child: IconButton(
                    onPressed: _togglePause,
                    icon: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ),
                ),
                if (_playerHpRatio < GameConstants.lowHealthThreshold)
                  _buildVignetteOverlay(),
                // Mini-map radar (bottom-right)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _buildMiniMap(),
                ),
              ],
            ),
          ),
          if (_isPaused) _buildPauseOverlay(s),
          if (_isGameOver) _buildGameOverOverlay(s),
          if (_showTutorial)
            TutorialOverlay(
              locale: locale,
              onComplete: () {
                setState(() => _showTutorial = false);
                _gameWorld.resumeEngine();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopHUD(S s) {
    final timeInt = _remainingTime.ceil();
    final isLowTime = timeInt <= 10;
    final combo = _gameWorld.comboCount;
    final level = _gameWorld.currentLevel;
    final xp = _gameWorld.currentXp;
    final xpNext = _gameWorld.xpToNextLevel;

    return Positioned(
      top: 8,
      left: 16,
      right: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _hudChip(
                s.t('wave', {'n': '${widget.waveNumber}'}),
                color: GameColors.accentGold,
              ),
              const SizedBox(width: 8),
              _hudChip(
                '$timeInt s',
                color: isLowTime ? GameColors.accentRed : Colors.white38,
                icon: Icons.timer,
              ),
              const SizedBox(width: 8),
              _hudChip(
                'x${_gameWorld.enemiesKilled}',
                color: Colors.white38,
                icon: Icons.star,
              ),
              const SizedBox(width: 8),
              _hudChip(
                'Lv.$level',
                color: GameColors.accentCyan,
                icon: Icons.arrow_upward,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // HP bar
          _buildHealthBar(_playerHpRatio),
          const SizedBox(height: 4),
          // XP bar
          _buildXpBar(xp, xpNext),
          // Combo counter
          if (combo >= 2)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildComboCounter(combo),
            ),
        ],
      ),
    );
  }

  Widget _hudChip(String label,
      {Color color = Colors.white38, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(double ratio) {
    final Color barColor;
    if (ratio > GameConstants.lowHealthThreshold) {
      barColor = GameColors.healthHigh;
    } else if (ratio > GameConstants.criticalHealthThreshold) {
      barColor = GameColors.healthMid;
    } else {
      barColor = GameColors.healthLow;
    }

    return Container(
      height: 10,
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ratio.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [barColor.withValues(alpha: 0.8), barColor],
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget _buildXpBar(int xp, int xpNext) {
    final ratio = (xp / xpNext).clamp(0.0, 1.0);
    return Container(
      height: 5,
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ratio,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GameColors.accentCyan.withValues(alpha: 0.6),
                GameColors.accentCyan,
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildComboCounter(int combo) {
    final intensity = (combo / 10.0).clamp(0.0, 1.0);
    final color = Color.lerp(GameColors.accentGold, GameColors.accentRed, intensity)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            'COMBO x$combo',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMap() {
    const radarSize = 80.0;
    const radarScale = 0.12; // world units to radar pixels
    final enemies = _gameWorld.getEnemyRelativePositions();

    return Container(
      width: radarSize,
      height: radarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: CustomPaint(
        size: const Size(radarSize, radarSize),
        painter: _RadarPainter(
          enemyPositions: enemies,
          scale: radarScale,
          radarRadius: radarSize / 2,
        ),
      ),
    );
  }

  Widget _buildVignetteOverlay() {
    final intensity =
        1 - (_playerHpRatio / GameConstants.lowHealthThreshold);
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                GameColors.accentRed.withValues(alpha: intensity * 0.5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(S s) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2030).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pause icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.accentGold.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.pause_circle_filled,
                    color: GameColors.accentGold, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                s.t('pause'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.t('wave', {'n': '${widget.waveNumber}'}),
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 28),
              // Resume button
              _pauseButton(
                icon: Icons.play_arrow_rounded,
                label: s.t('resume'),
                color: GameColors.accentGold,
                onTap: _togglePause,
                filled: true,
              ),
              const SizedBox(height: 10),
              // Settings button
              _pauseButton(
                icon: Icons.settings,
                label: s.t('settings'),
                color: GameColors.accentCyan,
                onTap: () => Navigator.pushNamed(context, AppRouter.settings),
              ),
              const SizedBox(height: 10),
              // Quit button
              _pauseButton(
                icon: Icons.exit_to_app,
                label: s.t('return_to_menu'),
                color: GameColors.accentRed,
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRouter.startScreen, (_) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pauseButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(
            color: color.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: filled ? GameColors.backgroundDark : color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: filled ? GameColors.backgroundDark : color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(S s) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied,
                color: GameColors.accentRed, size: 72),
            const SizedBox(height: 16),
            Text(
              s.t('game_over'),
              style: const TextStyle(
                color: GameColors.accentRed,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.t('wave', {'n': '${widget.waveNumber}'}),
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRouter.startScreen, (_) => false),
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.accentGold,
                foregroundColor: GameColors.backgroundDark,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(s.t('return_to_menu')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the radar mini-map
class _RadarPainter extends CustomPainter {
  final List<List<double>> enemyPositions;
  final double scale;
  final double radarRadius;

  _RadarPainter({
    required this.enemyPositions,
    required this.scale,
    required this.radarRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Radar rings
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(center, radarRadius * 0.5, ringPaint);
    canvas.drawCircle(center, radarRadius * 0.75, ringPaint);

    // Cross-hair lines
    canvas.drawLine(
      Offset(center.dx, center.dy - radarRadius * 0.85),
      Offset(center.dx, center.dy + radarRadius * 0.85),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radarRadius * 0.85, center.dy),
      Offset(center.dx + radarRadius * 0.85, center.dy),
      ringPaint,
    );

    // Player dot (center, green)
    final playerPaint = Paint()..color = Colors.green;
    canvas.drawCircle(center, 3, playerPaint);

    // Enemy dots (red)
    final enemyPaint = Paint()..color = Colors.red.shade300;
    for (final pos in enemyPositions) {
      final dx = pos[0] * scale;
      final dy = pos[1] * scale;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > radarRadius - 4) {
        // Clamp to edge
        final clamped = radarRadius - 4;
        final ratio = clamped / dist;
        canvas.drawCircle(
          Offset(center.dx + dx * ratio, center.dy + dy * ratio),
          2,
          enemyPaint..color = Colors.red.shade200,
        );
      } else {
        canvas.drawCircle(
          Offset(center.dx + dx, center.dy + dy),
          2.5,
          enemyPaint..color = Colors.red.shade300,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}

