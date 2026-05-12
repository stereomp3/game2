import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/achievement_system.dart';

/// Achievement system provider (async init from SharedPreferences)
final achievementProvider =
    AsyncNotifierProvider<AchievementNotifier, AchievementSystem>(() {
  return AchievementNotifier();
});

class AchievementNotifier extends AsyncNotifier<AchievementSystem> {
  @override
  Future<AchievementSystem> build() async {
    final system = AchievementSystem();
    await system.load();
    return system;
  }

  /// Record end-of-run stats and check achievements
  Future<void> recordRunEnd({
    required int kills,
    required int goldEarned,
    required int wavesCleared,
    required int highestWave,
    required int merges,
    required int augmentsChosen,
  }) async {
    final system = state.value;
    if (system == null) return;

    await system.recordRunEnd(
      kills: kills,
      goldEarned: goldEarned,
      wavesCleared: wavesCleared,
      highestWave: highestWave,
      merges: merges,
      augmentsChosen: augmentsChosen,
    );

    ref.invalidateSelf();
  }

  /// Get newly unlocked achievements for toast display
  List<AchievementDef> popNewlyUnlocked() {
    final system = state.value;
    if (system == null) return [];
    return system.popNewlyUnlocked();
  }
}
