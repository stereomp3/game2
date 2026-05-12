import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/data_manager.dart';
import '../domain/weapon_system.dart';
import '../domain/augment_system.dart';

/// Game session state - tracks entire run state across waves
class GameSessionState {
  final String characterId;
  final int currentWave;
  final int gold;
  final InventorySystem inventory;
  final List<AugmentData> chosenAugments;
  final int totalKills;

  GameSessionState({
    required this.characterId,
    this.currentWave = 1,
    this.gold = 0,
    InventorySystem? inventory,
    this.chosenAugments = const [],
    this.totalKills = 0,
  }) : inventory = inventory ?? InventorySystem();

  GameSessionState copyWith({
    String? characterId,
    int? currentWave,
    int? gold,
    InventorySystem? inventory,
    List<AugmentData>? chosenAugments,
    int? totalKills,
  }) {
    return GameSessionState(
      characterId: characterId ?? this.characterId,
      currentWave: currentWave ?? this.currentWave,
      gold: gold ?? this.gold,
      inventory: inventory ?? this.inventory,
      chosenAugments: chosenAugments ?? this.chosenAugments,
      totalKills: totalKills ?? this.totalKills,
    );
  }

  /// Check if augment screen should show (every 3 waves)
  bool get shouldShowAugment => currentWave > 1 && currentWave % 3 == 1;

  /// Get IDs of already chosen augments
  Set<String> get chosenAugmentIds =>
      chosenAugments.map((a) => a.id).toSet();
}

/// Game session provider - manages run state across screens
final gameSessionProvider =
    NotifierProvider<GameSessionNotifier, GameSessionState>(() {
  return GameSessionNotifier();
});

class GameSessionNotifier extends Notifier<GameSessionState> {
  @override
  GameSessionState build() {
    return GameSessionState(characterId: 'novice');
  }

  /// Start a new game run
  void startNewRun(String characterId) {
    final session = GameSessionState(characterId: characterId);
    
    // Assign initial weapon based on character
    String initialWeaponId = 'longsword';
    if (characterId == 'pyromaniac') {
      initialWeaponId = 'fire_staff';
    } else if (characterId == 'ninja') {
      initialWeaponId = 'dagger';
    } else if (characterId == 'alchemist') {
      initialWeaponId = 'poison_dagger';
    } else if (characterId == 'tank') {
      initialWeaponId = 'iron_shield';
    }
    
    try {
      final initialWeapon = DataManager.weapons.firstWhere((w) => w.id == initialWeaponId);
      session.inventory.addWeapon(initialWeapon);
    } catch (_) {
      if (DataManager.weapons.isNotEmpty) {
        session.inventory.addWeapon(DataManager.weapons.first);
      }
    }
    
    state = session;
  }

  /// Complete a wave - add gold and kills
  void completeWave(int goldEarned, int kills) {
    state = state.copyWith(
      gold: state.gold + goldEarned,
      totalKills: state.totalKills + kills,
    );
    state.inventory.setGold(state.gold);
  }

  /// Advance to next wave
  void advanceWave() {
    state = state.copyWith(currentWave: state.currentWave + 1);
  }

  /// Spend gold (shop purchase)
  bool spendGold(int amount) {
    if (state.gold < amount) return false;
    state = state.copyWith(gold: state.gold - amount);
    state.inventory.setGold(state.gold);
    return true;
  }

  /// Add gold
  void earnGold(int amount) {
    state = state.copyWith(gold: state.gold + amount);
    state.inventory.setGold(state.gold);
  }

  /// Choose an augment
  void chooseAugment(AugmentData augment) {
    state = state.copyWith(
      chosenAugments: [...state.chosenAugments, augment],
    );
  }

  /// Get current inventory
  InventorySystem get inventory => state.inventory;
}
