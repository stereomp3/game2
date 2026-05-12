import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_provider.dart';
import '../application/achievement_provider.dart';
import '../domain/achievement_system.dart';

/// Achievements screen - shows all achievements with progress
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final achievementAsync = ref.watch(achievementProvider);

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.t('achievements'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    achievementAsync.when(
                      data: (sys) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: GameColors.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${sys.unlockedCount}/${sys.totalAchievements}',
                          style: const TextStyle(
                            color: GameColors.accentGold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              // Achievement list
              Expanded(
                child: achievementAsync.when(
                  data: (sys) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: AchievementDatabase.all.length,
                    itemBuilder: (context, index) {
                      final def = AchievementDatabase.all[index];
                      return _buildAchievementCard(def, sys, s);
                    },
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: GameColors.accentGold,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
      AchievementDef def, AchievementSystem sys, S s) {
    final unlocked = sys.isUnlocked(def.id);
    final progress = sys.getProgress(def);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? GameColors.accentGold.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? GameColors.accentGold.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: unlocked
                  ? GameColors.accentGold.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                unlocked ? def.iconEmoji : '🔒',
                style: TextStyle(
                  fontSize: 24,
                  color: unlocked ? null : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t(def.nameKey),
                  style: TextStyle(
                    color: unlocked ? GameColors.accentGold : Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.t(def.descKey),
                  style: TextStyle(
                    color: unlocked ? Colors.white38 : Colors.white24,
                    fontSize: 12,
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        GameColors.accentGold.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Checkmark
          if (unlocked)
            const Icon(Icons.check_circle,
                color: GameColors.accentGold, size: 22),
        ],
      ),
    );
  }
}
