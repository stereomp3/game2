import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Achievement definition (data-driven)
class AchievementDef {
  final String id;
  final String nameKey;     // i18n key
  final String descKey;     // i18n key
  final String iconEmoji;
  final AchievementCondition condition;

  const AchievementDef({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.iconEmoji,
    required this.condition,
  });
}

/// Achievement unlock condition
class AchievementCondition {
  final String stat;       // which stat to check
  final double threshold;  // value to reach

  const AchievementCondition({
    required this.stat,
    required this.threshold,
  });
}

/// Player stats tracked for achievements
class PlayerLifetimeStats {
  int totalKills;
  int totalGoldEarned;
  int totalWavesCleared;
  int totalRunsPlayed;
  int highestWave;
  int totalMerges;
  int totalAugmentsChosen;
  int totalDeaths;

  PlayerLifetimeStats({
    this.totalKills = 0,
    this.totalGoldEarned = 0,
    this.totalWavesCleared = 0,
    this.totalRunsPlayed = 0,
    this.highestWave = 0,
    this.totalMerges = 0,
    this.totalAugmentsChosen = 0,
    this.totalDeaths = 0,
  });

  double getStat(String key) {
    switch (key) {
      case 'total_kills': return totalKills.toDouble();
      case 'total_gold': return totalGoldEarned.toDouble();
      case 'waves_cleared': return totalWavesCleared.toDouble();
      case 'runs_played': return totalRunsPlayed.toDouble();
      case 'highest_wave': return highestWave.toDouble();
      case 'total_merges': return totalMerges.toDouble();
      case 'total_augments': return totalAugmentsChosen.toDouble();
      case 'total_deaths': return totalDeaths.toDouble();
      default: return 0;
    }
  }

  Map<String, dynamic> toJson() => {
    'totalKills': totalKills,
    'totalGoldEarned': totalGoldEarned,
    'totalWavesCleared': totalWavesCleared,
    'totalRunsPlayed': totalRunsPlayed,
    'highestWave': highestWave,
    'totalMerges': totalMerges,
    'totalAugmentsChosen': totalAugmentsChosen,
    'totalDeaths': totalDeaths,
  };

  factory PlayerLifetimeStats.fromJson(Map<String, dynamic> json) {
    return PlayerLifetimeStats(
      totalKills: json['totalKills'] as int? ?? 0,
      totalGoldEarned: json['totalGoldEarned'] as int? ?? 0,
      totalWavesCleared: json['totalWavesCleared'] as int? ?? 0,
      totalRunsPlayed: json['totalRunsPlayed'] as int? ?? 0,
      highestWave: json['highestWave'] as int? ?? 0,
      totalMerges: json['totalMerges'] as int? ?? 0,
      totalAugmentsChosen: json['totalAugmentsChosen'] as int? ?? 0,
      totalDeaths: json['totalDeaths'] as int? ?? 0,
    );
  }
}

/// All achievement definitions
class AchievementDatabase {
  static const List<AchievementDef> all = [
    // Kill milestones
    AchievementDef(
      id: 'first_blood',
      nameKey: 'ach_first_blood',
      descKey: 'ach_first_blood_desc',
      iconEmoji: '🗡️',
      condition: AchievementCondition(stat: 'total_kills', threshold: 1),
    ),
    AchievementDef(
      id: 'slayer_50',
      nameKey: 'ach_slayer_50',
      descKey: 'ach_slayer_50_desc',
      iconEmoji: '⚔️',
      condition: AchievementCondition(stat: 'total_kills', threshold: 50),
    ),
    AchievementDef(
      id: 'slayer_500',
      nameKey: 'ach_slayer_500',
      descKey: 'ach_slayer_500_desc',
      iconEmoji: '💀',
      condition: AchievementCondition(stat: 'total_kills', threshold: 500),
    ),
    // Wave milestones
    AchievementDef(
      id: 'survivor_5',
      nameKey: 'ach_survivor_5',
      descKey: 'ach_survivor_5_desc',
      iconEmoji: '🛡️',
      condition: AchievementCondition(stat: 'highest_wave', threshold: 5),
    ),
    AchievementDef(
      id: 'survivor_10',
      nameKey: 'ach_survivor_10',
      descKey: 'ach_survivor_10_desc',
      iconEmoji: '🏆',
      condition: AchievementCondition(stat: 'highest_wave', threshold: 10),
    ),
    AchievementDef(
      id: 'survivor_20',
      nameKey: 'ach_survivor_20',
      descKey: 'ach_survivor_20_desc',
      iconEmoji: '👑',
      condition: AchievementCondition(stat: 'highest_wave', threshold: 20),
    ),
    // Economy milestones
    AchievementDef(
      id: 'rich_1000',
      nameKey: 'ach_rich_1000',
      descKey: 'ach_rich_1000_desc',
      iconEmoji: '💰',
      condition: AchievementCondition(stat: 'total_gold', threshold: 1000),
    ),
    // Merge milestones
    AchievementDef(
      id: 'blacksmith',
      nameKey: 'ach_blacksmith',
      descKey: 'ach_blacksmith_desc',
      iconEmoji: '🔨',
      condition: AchievementCondition(stat: 'total_merges', threshold: 10),
    ),
    // Run milestones
    AchievementDef(
      id: 'veteran_10',
      nameKey: 'ach_veteran_10',
      descKey: 'ach_veteran_10_desc',
      iconEmoji: '🎖️',
      condition: AchievementCondition(stat: 'runs_played', threshold: 10),
    ),
    // Death milestone
    AchievementDef(
      id: 'die_hard',
      nameKey: 'ach_die_hard',
      descKey: 'ach_die_hard_desc',
      iconEmoji: '💪',
      condition: AchievementCondition(stat: 'total_deaths', threshold: 50),
    ),
  ];
}

/// Achievement system with persistence
class AchievementSystem {
  static const _statsKey = 'player_lifetime_stats';
  static const _unlockedKey = 'unlocked_achievements';

  PlayerLifetimeStats _stats = PlayerLifetimeStats();
  final Set<String> _unlocked = {};
  final List<AchievementDef> _newlyUnlocked = [];

  PlayerLifetimeStats get stats => _stats;
  Set<String> get unlockedIds => Set.unmodifiable(_unlocked);
  int get totalAchievements => AchievementDatabase.all.length;
  int get unlockedCount => _unlocked.length;

  /// Pop newly unlocked achievements (for display)
  List<AchievementDef> popNewlyUnlocked() {
    final result = List<AchievementDef>.from(_newlyUnlocked);
    _newlyUnlocked.clear();
    return result;
  }

  /// Load from shared preferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final statsJson = prefs.getString(_statsKey);
    if (statsJson != null) {
      try {
        _stats = PlayerLifetimeStats.fromJson(
            jsonDecode(statsJson) as Map<String, dynamic>);
      } catch (_) {
        _stats = PlayerLifetimeStats();
      }
    }

    final unlockedList = prefs.getStringList(_unlockedKey);
    if (unlockedList != null) {
      _unlocked.addAll(unlockedList);
    }
  }

  /// Save to shared preferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(_stats.toJson()));
    await prefs.setStringList(_unlockedKey, _unlocked.toList());
  }

  /// Update stats after a run and check achievements
  Future<void> recordRunEnd({
    required int kills,
    required int goldEarned,
    required int wavesCleared,
    required int highestWave,
    required int merges,
    required int augmentsChosen,
  }) async {
    _stats.totalKills += kills;
    _stats.totalGoldEarned += goldEarned;
    _stats.totalWavesCleared += wavesCleared;
    _stats.totalRunsPlayed += 1;
    _stats.totalDeaths += 1;
    _stats.totalMerges += merges;
    _stats.totalAugmentsChosen += augmentsChosen;
    if (highestWave > _stats.highestWave) {
      _stats.highestWave = highestWave;
    }

    _checkAchievements();
    await save();
  }

  void _checkAchievements() {
    for (final def in AchievementDatabase.all) {
      if (_unlocked.contains(def.id)) continue;

      final currentValue = _stats.getStat(def.condition.stat);
      if (currentValue >= def.condition.threshold) {
        _unlocked.add(def.id);
        _newlyUnlocked.add(def);
      }
    }
  }

  /// Check if a specific achievement is unlocked
  bool isUnlocked(String id) => _unlocked.contains(id);

  /// Get progress for a specific achievement (0.0 - 1.0)
  double getProgress(AchievementDef def) {
    final current = _stats.getStat(def.condition.stat);
    return (current / def.condition.threshold).clamp(0.0, 1.0);
  }
}
