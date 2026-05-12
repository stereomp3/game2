import 'dart:async';

/// 遊戲事件基礎類別
/// 所有跨系統事件都應繼承此類別
abstract class GameEvent {
  final DateTime timestamp = DateTime.now();
}

/// 事件總線 — 發布/訂閱模式
/// 用於跨系統解耦通訊（UI ↔ 戰鬥、商店 ↔ 背包等）
/// 
/// 設計決策：使用 Dart StreamController 實作，
/// 相比自訂 Observer 模式更符合 Dart 慣例，且支援 async
class EventBus {
  // 單例模式
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final StreamController<GameEvent> _controller =
      StreamController<GameEvent>.broadcast();

  /// 發布事件
  void fire(GameEvent event) {
    _controller.add(event);
  }

  /// 訂閱特定類型的事件
  /// 回傳 StreamSubscription，呼叫者需自行管理生命週期
  StreamSubscription<T> on<T extends GameEvent>(void Function(T event) handler) {
    return _controller.stream
        .where((event) => event is T)
        .cast<T>()
        .listen(handler);
  }

  /// 取得特定類型事件的 Stream
  Stream<T> stream<T extends GameEvent>() {
    return _controller.stream
        .where((event) => event is T)
        .cast<T>();
  }

  /// 清理資源
  void dispose() {
    _controller.close();
  }
}

// ===== 常用遊戲事件定義 =====

/// 場景切換事件
class SceneChangeEvent extends GameEvent {
  final String targetScene;
  SceneChangeEvent(this.targetScene);
}

/// 語言切換事件
class LocaleChangeEvent extends GameEvent {
  final String localeCode;
  LocaleChangeEvent(this.localeCode);
}

/// 角色解鎖事件
class CharacterUnlockedEvent extends GameEvent {
  final String characterId;
  CharacterUnlockedEvent(this.characterId);
}

/// 波次開始事件
class WaveStartEvent extends GameEvent {
  final int waveNumber;
  WaveStartEvent(this.waveNumber);
}

/// 波次結束事件
class WaveEndEvent extends GameEvent {
  final int waveNumber;
  final int goldEarned;
  WaveEndEvent(this.waveNumber, this.goldEarned);
}

/// 玩家死亡事件
class PlayerDeathEvent extends GameEvent {
  final String playerId;
  PlayerDeathEvent(this.playerId);
}

/// 商品購買事件
class ItemPurchasedEvent extends GameEvent {
  final String itemId;
  final int cost;
  ItemPurchasedEvent(this.itemId, this.cost);
}

/// 武器合成事件
class WeaponMergedEvent extends GameEvent {
  final String weaponId;
  final int newQuality;
  WeaponMergedEvent(this.weaponId, this.newQuality);
}
