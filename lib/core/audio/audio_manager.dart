/// Audio event types
enum SfxType {
  hit,
  critHit,
  enemyDeath,
  playerHurt,
  playerDeath,
  waveClear,
  waveStart,
  purchase,
  sell,
  merge,
  augmentSelect,
  buttonClick,
  goldPickup,
}

/// Background music tracks
enum BgmTrack {
  menuTheme,
  combatNormal,
  combatIntense,
  shopTheme,
  gameOver,
}

/// Audio manager interface (decoupled from implementation)
/// Future: Implement with flame_audio or audioplayers package
abstract class IAudioManager {
  /// Play a one-shot sound effect
  void playSfx(SfxType sfx);

  /// Start playing background music
  void playBgm(BgmTrack track);

  /// Stop background music
  void stopBgm();

  /// Set master volume (0.0 - 1.0)
  void setMasterVolume(double volume);

  /// Set SFX volume (0.0 - 1.0)
  void setSfxVolume(double volume);

  /// Set BGM volume (0.0 - 1.0)
  void setBgmVolume(double volume);

  /// Dispose resources
  void dispose();
}

/// Stub implementation - prints audio events for debugging
/// Replace with real implementation when audio assets are ready
class StubAudioManager implements IAudioManager {
  double _masterVolume = 1.0;
  double _sfxVolume = 0.7;
  double _bgmVolume = 0.5;
  BgmTrack? _currentBgm;

  // SFX file mappings (placeholder paths)
  static const Map<SfxType, String> _sfxPaths = {
    SfxType.hit: 'audio/sfx/hit.wav',
    SfxType.critHit: 'audio/sfx/crit_hit.wav',
    SfxType.enemyDeath: 'audio/sfx/enemy_death.wav',
    SfxType.playerHurt: 'audio/sfx/player_hurt.wav',
    SfxType.playerDeath: 'audio/sfx/player_death.wav',
    SfxType.waveClear: 'audio/sfx/wave_clear.wav',
    SfxType.waveStart: 'audio/sfx/wave_start.wav',
    SfxType.purchase: 'audio/sfx/purchase.wav',
    SfxType.sell: 'audio/sfx/sell.wav',
    SfxType.merge: 'audio/sfx/merge.wav',
    SfxType.augmentSelect: 'audio/sfx/augment_select.wav',
    SfxType.buttonClick: 'audio/sfx/button_click.wav',
    SfxType.goldPickup: 'audio/sfx/gold_pickup.wav',
  };

  // BGM file mappings (placeholder paths)
  static const Map<BgmTrack, String> _bgmPaths = {
    BgmTrack.menuTheme: 'audio/bgm/menu_theme.ogg',
    BgmTrack.combatNormal: 'audio/bgm/combat_normal.ogg',
    BgmTrack.combatIntense: 'audio/bgm/combat_intense.ogg',
    BgmTrack.shopTheme: 'audio/bgm/shop_theme.ogg',
    BgmTrack.gameOver: 'audio/bgm/game_over.ogg',
  };

  @override
  void playSfx(SfxType sfx) {
    if (_masterVolume <= 0 || _sfxVolume <= 0) return;
    // Stub: print for debugging
    // In production: FlameAudio.play(_sfxPaths[sfx]!, volume: _sfxVolume * _masterVolume);
    final _ = _sfxPaths[sfx]; // Keep reference to suppress unused warning
  }

  @override
  void playBgm(BgmTrack track) {
    if (_currentBgm == track) return;
    if (_masterVolume <= 0 || _bgmVolume <= 0) return;
    _currentBgm = track;
    // Stub: no-op
    // In production: FlameAudio.bgm.play(_bgmPaths[track]!, volume: _bgmVolume * _masterVolume);
    final _ = _bgmPaths[track];
  }

  @override
  void stopBgm() {
    _currentBgm = null;
    // In production: FlameAudio.bgm.stop();
  }

  @override
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
  }

  @override
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  @override
  void setBgmVolume(double volume) {
    _bgmVolume = volume.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    stopBgm();
  }
}

/// Global audio manager singleton
/// Access via AudioManager.instance
class AudioManager {
  AudioManager._();

  static final IAudioManager instance = StubAudioManager();
}
