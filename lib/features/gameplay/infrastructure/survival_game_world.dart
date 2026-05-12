import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/events/event_bus.dart';
import '../domain/attribute_system.dart';
import '../domain/weapon_system.dart';
import '../domain/weapon_effect_processor.dart';
import 'player_components.dart';
import 'enemy_components.dart';
import 'game_entity_component.dart';
import 'visual_effects.dart';

/// Virtual joystick component
class VirtualJoystick extends PositionComponent with DragCallbacks {
  static const _outerRadius = 60.0;
  static const _innerRadius = 24.0;

  Vector2 _knobPos = Vector2.zero();
  Vector2 get direction =>
      _knobPos.length > 0.1 ? _knobPos.normalized() : Vector2.zero();

  late CircleComponent _outerCircle;
  late CircleComponent _innerKnob;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(_outerRadius * 2);
    _outerCircle = CircleComponent(
      radius: _outerRadius,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.08),
      anchor: Anchor.center,
      position: Vector2.all(_outerRadius),
    );
    _outerCircle.add(CircleComponent(
      radius: _outerRadius,
      paint: Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
      anchor: Anchor.center,
    ));

    _innerKnob = CircleComponent(
      radius: _innerRadius,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.25),
      anchor: Anchor.center,
      position: Vector2.all(_outerRadius),
    );

    await addAll([_outerCircle, _innerKnob]);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final center = Vector2.all(_outerRadius);
    final delta = event.localEndPosition - center;
    final clampedDelta = delta.length > _outerRadius
        ? delta.normalized() * _outerRadius
        : delta;
    _knobPos = clampedDelta / _outerRadius;
    _innerKnob.position = center + clampedDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _knobPos = Vector2.zero();
    _innerKnob.position = Vector2.all(_outerRadius);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final center = Vector2.all(_outerRadius);
    return (point - center).length <= _outerRadius;
  }
}

/// Main game world (Flame FlameGame)
///
/// Responsibilities:
/// - Manage player and enemy entity lifecycles
/// - Drive movement/attack/AI logic
/// - Communicate wave completion, player death via EventBus
/// - Does not directly modify Flutter UI (decoupled)
class SurvivalGameWorld extends FlameGame with HasCollisionDetection {
  final String characterId;
  final int waveNumber;
  final EventBus eventBus;
  final Map<String, double> bonusStatMap;
  final List<WeaponData?> equippedWeapons;
  final List<WeaponData> equippedItems;

  late PlayerComponent _player;
  late VirtualJoystick _joystick;
  final _enemies = <EnemyComponent>[];
  final _random = Random();

  double _waveTimer = 0;
  double _enemySpawnTimer = 0;
  int _enemiesKilled = 0;
  bool _waveComplete = false;
  double _attackScanTimer = 0;
  bool _isReady = false;

  // XP / Level system
  int _currentXp = 0;
  int _currentLevel = 1;
  int get xpToNextLevel => 10 + (_currentLevel * 5);

  // Combo kill system
  int _comboCount = 0;
  double _comboTimer = 0;
  static const _comboWindow = 2.0; // seconds

  SurvivalGameWorld({
    required this.characterId,
    required this.waveNumber,
    required this.eventBus,
    this.bonusStatMap = const {},
    this.equippedWeapons = const [],
    this.equippedItems = const [],
  });

  @override
  Color backgroundColor() => const Color(0xFF1A3A2A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add ground tiles
    await _addGroundTiles();

    _player = createPlayer(characterId, position: size / 2);

    // Apply bonus stats from inventory + augments
    if (bonusStatMap.isNotEmpty) {
      _player.bonusStats = EntityStats(
        maxHp: bonusStatMap['max_hp'] ?? 0,
        hpRegen: bonusStatMap['hp_regen'] ?? 0,
        lifesteal: bonusStatMap['lifesteal'] ?? 0,
        armor: bonusStatMap['armor'] ?? 0,
        dodge: bonusStatMap['dodge'] ?? 0,
        moveSpeed: bonusStatMap['move_speed'] ?? 0,
        meleeDmg: bonusStatMap['melee_dmg'] ?? 0,
        rangedDmg: bonusStatMap['ranged_dmg'] ?? 0,
        elementalDmg: bonusStatMap['elemental_dmg'] ?? 0,
        attackSpeed: 1.0 + (bonusStatMap['attack_speed'] ?? 0),
        critChance: bonusStatMap['crit_chance'] ?? 0,
        critDamage: bonusStatMap['crit_damage'] ?? 0,
        range: bonusStatMap['range'] ?? 0,
        knockback: bonusStatMap['knockback'] ?? 0,
        cooldownReduction: bonusStatMap['cooldown_reduction'] ?? 0,
        pickupRadius: bonusStatMap['pickup_radius'] ?? 0,
        luck: bonusStatMap['luck'] ?? 0,
        debuffDuration: 1.0 + (bonusStatMap['debuff_duration'] ?? 0),
        statusEffectiveness: 1.0 + (bonusStatMap['status_effectiveness'] ?? 0),
      );
      _player.currentHp = _player.stats.maxHp;
    }

    await world.add(_player);
    _player.updateWeapons(equippedWeapons);

    // Camera follows player
    camera.follow(_player);

    _joystick = VirtualJoystick()
      ..position = Vector2(80, size.y - 180);
    await camera.viewport.add(_joystick);

    await _spawnWave();
    eventBus.fire(WaveStartEvent(waveNumber));

    // Wave start banner
    world.add(WaveBannerEffect(
      waveNumber: waveNumber,
      position: _player.position + Vector2(0, -60),
    ));
    _isReady = true;
  }

  /// Add procedural ground tiles for visual variety
  Future<void> _addGroundTiles() async {
    const tileSize = 120.0;
    const gridRange = 12;
    final darkGreen = const Color(0xFF1A3A2A);
    final lightGreen = const Color(0xFF1F4232);
    final accentGreen = const Color(0xFF254D3A);

    for (int x = -gridRange; x <= gridRange; x++) {
      for (int y = -gridRange; y <= gridRange; y++) {
        final isAlt = (x + y) % 2 == 0;
        final tile = RectangleComponent(
          position: Vector2(x * tileSize, y * tileSize),
          size: Vector2.all(tileSize),
          paint: Paint()..color = isAlt ? darkGreen : lightGreen,
        );
        await world.add(tile);
      }
    }

    // Arena boundary ring markers
    const arenaRadius = 600.0;
    const markerCount = 24;
    for (int i = 0; i < markerCount; i++) {
      final angle = (i / markerCount) * 2 * pi;
      final markerPos = (size / 2) +
          Vector2(cos(angle) * arenaRadius, sin(angle) * arenaRadius);
      await world.add(CircleComponent(
        radius: 6,
        position: markerPos,
        anchor: Anchor.center,
        paint: Paint()..color = accentGreen.withValues(alpha: 0.5),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_waveComplete) return;

    _waveTimer += dt;
    if (_waveTimer >= GameConstants.waveDurationSeconds) {
      _onWaveComplete();
      return;
    }

    _updatePlayerMovement(dt);
    _updateEnemyAI(dt);

    _attackScanTimer += dt;
    if (_attackScanTimer >= 0.1) {
      _attackScanTimer = 0;
      _performAutoAttack();
    }

    _enemySpawnTimer += dt;
    final spawnInterval = _getSpawnInterval();
    if (_enemySpawnTimer >= spawnInterval) {
      _enemySpawnTimer = 0;
      _spawnEnemy();
    }

    // Combo timer decay
    if (_comboCount > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _comboCount = 0;
      }
    }
  }

  void _updatePlayerMovement(double dt) {
    final dir = _joystick.direction;
    if (dir.length > 0.1) {
      _player.move(dir, dt);
      _player.facingDirection = dir.x < 0 ? -1 : 1;
    } else {
      _player.stopMoving();
    }
  }

  void _updateEnemyAI(double dt) {
    final deadEnemies = <EnemyComponent>[];
    for (final enemy in _enemies) {
      if (!enemy.isLoaded) continue;
      if (!enemy.isAlive) {
        deadEnemies.add(enemy);
        continue;
      }
      final dir = enemy.getAIDirection(dt, _player.position);
      if (dir.length > 0.1) {
        enemy.move(dir, dt);
        enemy.facingDirection = dir.x < 0 ? -1 : 1;
        final dist = enemy.position.distanceTo(_player.position);
        if (dist < 40 && enemy.canAttack) {
          enemy.resetAttackCooldown();
          enemy.setEntityState(EntityState.attack);
          final dmg = enemy.stats.meleeDmg;
          _player.takeDamage(dmg);

          // Hit spark on player
          if (dmg > 0.5) {
            world.add(HitSparkEffect(
              position: _player.position.clone(),
              color: Colors.red.shade300,
              particleCount: 4,
            ));
          }

          if (!_player.isAlive) {
            _onPlayerDead();
          }
        }
      }
    }

    for (final dead in deadEnemies) {
      // Death explosion VFX
      world.add(DeathExplosionEffect(
        position: dead.position.clone(),
        entityColor: dead.entityColor,
      ));
      // Gold pickup VFX
      world.add(GoldPickupEffect(
        position: dead.position.clone() + Vector2(0, -20),
        amount: GameConstants.baseKillGold,
      ));

      _enemies.remove(dead);
      _enemiesKilled++;

      // XP system
      _currentXp += 1 + (waveNumber ~/ 3);
      if (_currentXp >= xpToNextLevel) {
        _currentXp -= xpToNextLevel;
        _currentLevel++;
        // Level-up stat boost
        _player.bonusStats = _player.bonusStats.add(const EntityStats(
          maxHp: 5, meleeDmg: 2, rangedDmg: 1, elementalDmg: 1,
          armor: 0.01, moveSpeed: 3,
        ));
        _player.currentHp = _player.stats.maxHp;
        // Level-up VFX
        world.add(WaveBannerEffect(
          waveNumber: _currentLevel,
          position: _player.position + Vector2(0, -50),
        ));
      }

      // Combo system
      _comboCount++;
      _comboTimer = _comboWindow;

      eventBus.fire(
          ItemPurchasedEvent('kill_gold', GameConstants.baseKillGold));
    }
  }

  void _performAutoAttack() {
    if (!_player.isAlive) return;
    if (_enemies.isEmpty) return;

    if (_player.playerVisual.weaponContainer.children.isEmpty) return;

    // We check each weapon independently
    for (int i = 0; i < equippedWeapons.length; i++) {
      final weaponData = equippedWeapons[i];
      if (weaponData == null) continue;

      if (_player.weaponCooldowns[i] > 0) continue;

      // Find nearest enemy for THIS weapon
      EnemyComponent? nearest;
      double nearestDist = double.infinity;
      for (final enemy in _enemies) {
        if (!enemy.isLoaded || !enemy.isAlive) continue;
        final dist = _player.position.distanceTo(enemy.position);
        if (dist < _player.stats.range && dist < nearestDist) {
          nearestDist = dist;
          nearest = enemy;
        }
      }

      if (nearest != null) {
        // We found an enemy to attack with this weapon!
        
        // Reset cooldown
        final attackSpeed = _player.stats.attackSpeed;
        _player.weaponCooldowns[i] = weaponData.baseCooldown / (attackSpeed > 0 ? attackSpeed : 1);

        // Visual swing animation
        if (i < _player.playerVisual.weaponContainer.children.length) {
          final visualComp = _player.playerVisual.weaponContainer.children.elementAt(i);
          if (visualComp is WeaponVisualComponent) {
            visualComp.swing();
          }
        }

        final isRanged = weaponData.isRanged;

        if (isRanged) {
          world.add(ProjectileEffect(
            position: _player.position.clone(),
            target: nearest,
            onHit: () {
              if (nearest!.isAlive) {
                // Apply damage
                final dmg = _player.stats.rangedDmg > 0 ? _player.stats.rangedDmg : _player.stats.meleeDmg;
                nearest.takeDamage(dmg);
                _applyHitEffects(nearest, [weaponData], dmg);
              }
            },
          ));
        } else {
          final angle = atan2(
              nearest.position.y - _player.position.y,
              nearest.position.x - _player.position.x);
          world.add(SlashEffect(
            position: _player.position.clone() + Vector2(cos(angle) * 20, sin(angle) * 20),
            radius: _player.stats.range * 0.8,
            attackAngle: angle,
            color: _player.entityColor,
          ));
          nearest.takeDamage(_player.stats.meleeDmg);
          _applyHitEffects(nearest, [weaponData], _player.stats.meleeDmg);
        }
      }
    }
  }

  void _applyHitEffects(EnemyComponent nearest, List<WeaponData?> weapons, double baseDamage) {
    // Hit spark at enemy position
    world.add(HitSparkEffect(
      position: nearest.position.clone(),
      color: _player.entityColor,
      particleCount: 6,
    ));

    // Damage number
    world.add(DamageNumberEffect(
      position: nearest.position.clone() + Vector2(0, -24),
      damage: baseDamage,
    ));

    // Apply weapon special effects
    final weaponEffects = WeaponEffectProcessor.processOnHit(
      equippedWeapons: weapons,
      equippedItems: equippedItems,
      baseDamage: baseDamage,
      statusEffectiveness: _player.stats.statusEffectiveness,
    );
    for (final effect in weaponEffects) {
      nearest.statusEffects.applyEffect(
        effect,
        durationMultiplier: _player.stats.debuffDuration,
      );
    }
  }

  // Replaced by _applyHitEffects above

  Future<void> _spawnWave() async {
    final count = min(
      GameConstants.baseEnemyCount + waveNumber * 3,
      GameConstants.maxEnemiesOnScreen,
    );
    for (int i = 0; i < count ~/ 2; i++) {
      await _spawnEnemy();
    }
  }

  Future<void> _spawnEnemy() async {
    if (_enemies.length >= GameConstants.maxEnemiesOnScreen) return;

    final angle = _random.nextDouble() * 2 * pi;
    final spawnDist = 280.0 + _random.nextDouble() * 80;
    final spawnPos = _player.position +
        Vector2(cos(angle) * spawnDist, sin(angle) * spawnDist);

    final enemy = EnemyFactory.spawn(waveNumber, position: spawnPos);
    _enemies.add(enemy);
    await world.add(enemy);
  }

  double _getSpawnInterval() {
    final base = GameConstants.baseSpawnInterval;
    return (base - waveNumber * 0.15).clamp(0.8, base);
  }

  void _onWaveComplete() {
    _waveComplete = true;
    eventBus.fire(WaveEndEvent(waveNumber, GameConstants.baseWaveGold));
  }

  void _onPlayerDead() {
    _waveComplete = true;
    eventBus.fire(PlayerDeathEvent('player'));
  }

  // Public getters for HUD
  double get waveProgress =>
      (_waveTimer / GameConstants.waveDurationSeconds).clamp(0, 1);
  double get playerHpRatio => (_isReady && _player.isAlive) ? _player.hpRatio : 1.0;
  int get enemiesKilled => _enemiesKilled;
  int get enemiesOnScreen => _enemies.length;
  double get remainingTime =>
      (GameConstants.waveDurationSeconds - _waveTimer)
          .clamp(0, double.infinity);
  int get currentLevel => _currentLevel;
  int get currentXp => _currentXp;
  int get comboCount => _comboCount;
  double get comboTimer => _comboTimer;

  /// Get enemy positions relative to player (for mini-map)
  /// Returns [dx, dy] pairs to avoid Vector2 import in presentation
  List<List<double>> getEnemyRelativePositions() {
    if (!_isReady || !_player.isAlive) return [];
    return _enemies
        .where((e) => e.isLoaded && e.isAlive)
        .map((e) {
          final rel = e.position - _player.position;
          return [rel.x, rel.y];
        })
        .toList();
  }
}
