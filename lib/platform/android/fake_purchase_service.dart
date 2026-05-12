import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake Purchase Provider (Riverpod 3.x AsyncNotifier)
final fakePurchaseProvider =
    AsyncNotifierProvider<FakePurchaseNotifier, FakePurchaseState>(() {
  return FakePurchaseNotifier();
});

/// Purchase status enum
enum PurchaseStatus {
  idle,
  processing,
  success,
  unlocked,
}

/// Purchase state
class FakePurchaseState {
  final PurchaseStatus status;
  final Set<String> unlockedCharacters;

  const FakePurchaseState({
    this.status = PurchaseStatus.idle,
    this.unlockedCharacters = const {},
  });

  FakePurchaseState copyWith({
    PurchaseStatus? status,
    Set<String>? unlockedCharacters,
  }) {
    return FakePurchaseState(
      status: status ?? this.status,
      unlockedCharacters: unlockedCharacters ?? this.unlockedCharacters,
    );
  }
}

/// Fake purchase service - simulates Google Billing flow
class FakePurchaseNotifier extends AsyncNotifier<FakePurchaseState> {
  static const _prefsKey = 'unlocked_characters';

  @override
  Future<FakePurchaseState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    return FakePurchaseState(
      unlockedCharacters: saved.toSet(),
    );
  }

  /// Start a simulated purchase flow
  Future<void> startPurchase(String characterId) async {
    final current = state.value ?? const FakePurchaseState();

    // Phase 1: Processing
    state = AsyncData(current.copyWith(status: PurchaseStatus.processing));
    await Future.delayed(const Duration(seconds: 2));

    // Phase 2: Success
    final newUnlocked = {...current.unlockedCharacters, characterId};
    state = AsyncData(FakePurchaseState(
      status: PurchaseStatus.success,
      unlockedCharacters: newUnlocked,
    ));

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, newUnlocked.toList());

    // Phase 3: Show success briefly, then reset to idle
    await Future.delayed(const Duration(seconds: 1));
    state = AsyncData(FakePurchaseState(
      status: PurchaseStatus.idle,
      unlockedCharacters: newUnlocked,
    ));
  }
}
