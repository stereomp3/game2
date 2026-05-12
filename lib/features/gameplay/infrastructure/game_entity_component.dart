import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../domain/attribute_system.dart';
import '../domain/status_effect_system.dart';
import '../../../core/constants/game_constants.dart';

/// Entity state machine
enum EntityState {
  idle,
  move,
  attack,
  hurt,
  dead,
}

/// Base game entity component (Flame Component)
///
/// Design: All entities (player/enemy) inherit this class.
/// Uses procedural animation to drive a single static image.
/// StatusEffectSystem injected via composition, not inheritance.
/// EntityStats is immutable; bonuses stacked via bonusStats.
///
/// Sprite loading: Override [spritePath] to load a sprite image.
/// Falls back to colored rectangle if sprite is unavailable.
abstract class GameEntityComponent extends PositionComponent {
  final String entityId;
  final EntityStats baseStats;
  EntityStats bonusStats;

  EntityStats get stats => baseStats.add(bonusStats);

  double currentHp;
  double _hpRegenTimer = 0;
  bool get isAlive => currentHp > 0;
  double get hpRatio => (currentHp / stats.maxHp).clamp(0.0, 1.0);

  EntityState _state = EntityState.idle;
  EntityState get entityState => _state;

  final StatusEffectSystem statusEffects = StatusEffectSystem();

  double animTimer = 0;
  double _hurtTimer = 0;
  bool _isFlashingWhite = false;
  Vector2 _velocity = Vector2.zero();
  double facingDirection = 1.0;
  final _dodgeRandom = Random();

  // Visual components - sprite or rectangle fallback
  late PositionComponent visualBody;
  late RectangleComponent _hurtOverlay;
  RectangleComponent? _hpBarBg;
  RectangleComponent? _hpBarFill;

  GameEntityComponent({
    required this.entityId,
    required this.baseStats,
    EntityStats? bonusStats,
    super.position,
    super.size,
    super.anchor,
  })  : bonusStats = bonusStats ??
            const EntityStats(
              maxHp: 0, hpRegen: 0, lifesteal: 0, armor: 0, dodge: 0,
              moveSpeed: 0, meleeDmg: 0, rangedDmg: 0, elementalDmg: 0,
              attackSpeed: 1.0, critChance: 0, critDamage: 0, range: 0,
              knockback: 0, cooldownReduction: 0, pickupRadius: 0, luck: 0,
              debuffDuration: 1.0, statusEffectiveness: 1.0,
            ),
        currentHp = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    currentHp = baseStats.maxHp;
    size = size == Vector2.zero() ? Vector2(48, 48) : size;

    visualBody = await buildVisualBody();

    _hurtOverlay = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.white.withValues(alpha: 0),
      anchor: Anchor.center,
      position: size / 2,
    );

    await addAll([visualBody, _hurtOverlay]);

    // Add HP bar (positioned above entity)
    if (showHpBar) {
      final maxWidth = size.x * 0.8;
      _hpBarBg = RectangleComponent(
        size: Vector2(maxWidth, 4),
        position: Vector2(size.x / 2 - maxWidth / 2, -8),
        paint: Paint()..color = Colors.black.withValues(alpha: 0.5),
        anchor: Anchor.centerLeft,
      );
      _hpBarFill = RectangleComponent(
        size: Vector2(maxWidth, 4),
        position: Vector2(size.x / 2 - maxWidth / 2, -8),
        paint: Paint()..color = _hpBarColor,
        anchor: Anchor.centerLeft,
      );
      await addAll([_hpBarBg!, _hpBarFill!]);
    }

    await onEntityLoad();
  }

  Future<PositionComponent> buildVisualBody() async {
    if (spritePath != null) {
      try {
        final sprite = await Sprite.load(spritePath!);
        return SpriteComponent(
          sprite: sprite,
          size: size,
          anchor: Anchor.center,
          position: size / 2,
        );
      } catch (_) {
        return _createFallbackRect();
      }
    } else {
      return _createFallbackRect();
    }
  }

  RectangleComponent _createFallbackRect() {
    return RectangleComponent(
      size: size,
      paint: Paint()..color = entityColor,
      anchor: Anchor.center,
      position: size / 2,
    );
  }

  Future<void> onEntityLoad() async {}

  /// Override to provide sprite image asset path (relative to assets/images/)
  /// Returns null to use colored rectangle fallback
  String? get spritePath => null;

  Color get entityColor => Colors.white;

  /// Override to show HP bar above entity (true for enemies)
  bool get showHpBar => false;

  Color get _hpBarColor {
    if (hpRatio > 0.6) return Colors.green;
    if (hpRatio > 0.3) return Colors.orange;
    return Colors.red;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    final statusDamage = statusEffects.tick(dt,
        effectivenessMultiplier: stats.statusEffectiveness);
    if (statusDamage > 0) {
      takeDamage(statusDamage, isTrueDamage: true);
    }

    _hpRegenTimer += dt;
    if (_hpRegenTimer >= 1.0) {
      _hpRegenTimer = 0;
      heal(stats.hpRegen);
    }

    _updateProceduralAnimation(dt);
    _updateHpBar();
  }

  void _updateHpBar() {
    if (_hpBarFill == null) return;
    final maxWidth = size.x * 0.8;
    _hpBarFill!.size.x = maxWidth * hpRatio;
    _hpBarFill!.paint.color = _hpBarColor;
    // Hide HP bar when full HP
    final show = hpRatio < 1.0;
    _hpBarBg!.paint.color = show
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.transparent;
    if (!show) {
      _hpBarFill!.paint.color = Colors.transparent;
    }
  }

  void _updateProceduralAnimation(double dt) {
    animTimer += dt;

    if (_isFlashingWhite) {
      _hurtTimer -= dt;
      if (_hurtTimer <= 0) {
        _isFlashingWhite = false;
        _hurtOverlay.paint.color = Colors.white.withValues(alpha: 0);
      }
    }

    switch (_state) {
      case EntityState.idle:
        animateIdle(dt);
      case EntityState.move:
        animateMove(dt);
      case EntityState.attack:
        animateAttack(dt);
      case EntityState.hurt:
      case EntityState.dead:
        break;
    }
  }

  void animateIdle(double dt) {
    final cycle = GameConstants.idleBreathCycle;
    final bobY = sin(animTimer * (2 * pi / cycle)) * 2.0;
    final breathScale = 1.0 + sin(animTimer * (2 * pi / cycle)) * 0.02;

    visualBody.position = Vector2(size.x / 2, size.y / 2 + bobY);
    visualBody.scale = Vector2(breathScale * facingDirection, breathScale);
  }

  void animateMove(double dt) {
    final cycle = GameConstants.walkBobbingCycle;
    final tilt = sin(animTimer * (2 * pi / cycle)) * 0.15;
    final bounceY = (sin(animTimer * (2 * pi / cycle / 2)) * 3.0).abs();
    final scaleX = 1.0 + sin(animTimer * (2 * pi / cycle)) * 0.05;
    final scaleY = 1.0 - sin(animTimer * (2 * pi / cycle)) * 0.05;

    visualBody.angle = tilt;
    visualBody.position = Vector2(size.x / 2, size.y / 2 - bounceY);
    visualBody.scale = Vector2(scaleX * facingDirection, scaleY);
  }

  void animateAttack(double dt) {
    final attackProgress = (animTimer % 0.4) / 0.4;
    final shakeX = sin(attackProgress * pi * 4) * 8.0;
    visualBody.angle = 0;
    visualBody.position = Vector2(size.x / 2 + shakeX, size.y / 2);
    visualBody.scale = Vector2(facingDirection, 1);
  }

  void setEntityState(EntityState newState) {
    if (_state == newState) return;
    _state = newState;
    animTimer = 0;
    resetVisualState();
  }

  void resetVisualState() {
    visualBody.angle = 0;
    visualBody.position = size / 2;
    visualBody.scale = Vector2(facingDirection, 1);
  }

  void takeDamage(double damage, {bool isTrueDamage = false}) {
    if (!isAlive) return;

    if (_dodgeRandom.nextDouble() < stats.dodge) return;

    final actualDamage = isTrueDamage
        ? damage
        : stats.calculateDamageReceived(damage);

    final finalDamage = statusEffects.isVulnerable
        ? actualDamage * (1 + GameConstants.vulnerableDamageMultiplier)
        : actualDamage;

    currentHp = (currentHp - finalDamage).clamp(0, stats.maxHp);

    _triggerHurtFlash();

    if (currentHp <= 0) {
      onDeath();
    }
  }

  void heal(double amount) {
    if (!isAlive) return;
    currentHp = (currentHp + amount).clamp(0, stats.maxHp);
  }

  void move(Vector2 direction, double dt) {
    if (!isAlive) return;
    if (statusEffects.isFrozen || statusEffects.isStunned) return;

    _velocity = direction.normalized() * stats.moveSpeed;
    position += _velocity * dt;

    if (direction.length > 0.1) {
      final bleedDmg = statusEffects.calculateBleedDamage(stats.moveSpeed * dt);
      if (bleedDmg > 0) takeDamage(bleedDmg, isTrueDamage: true);
    }

    if (_state != EntityState.move && _state != EntityState.attack) {
      setEntityState(EntityState.move);
    }
  }

  void stopMoving() {
    _velocity = Vector2.zero();
    if (_state == EntityState.move) {
      setEntityState(EntityState.idle);
    }
  }

  void _triggerHurtFlash() {
    _isFlashingWhite = true;
    _hurtTimer = GameConstants.hurtFlashDuration;
    _hurtOverlay.paint.color = Colors.white.withValues(alpha: 0.9);
    setEntityState(EntityState.hurt);

    Future.delayed(
      Duration(milliseconds: (GameConstants.hurtFlashDuration * 1000).toInt()),
      () {
        if (isAlive) setEntityState(EntityState.idle);
      },
    );
  }

  void onDeath() {
    setEntityState(EntityState.dead);
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.4),
        onComplete: removeFromParent,
      ),
    );
  }
}
