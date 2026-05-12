import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/data/data_manager.dart';
import 'game_entity_component.dart';

/// Enemy AI strategy interface (Strategy Pattern)
abstract class EnemyAI {
  Vector2 update(double dt, Vector2 selfPos, Vector2 targetPos,
      double distToTarget);
}

/// AI 1: Slime - direct chase
class SlimeAI implements EnemyAI {
  @override
  Vector2 update(double dt, Vector2 selfPos, Vector2 targetPos, double dist) {
    return (targetPos - selfPos).normalized();
  }
}

/// AI 2: Bat - S-wave chase
class BatAI implements EnemyAI {
  double _waveTimer = 0;
  final double _waveOffset;

  BatAI() : _waveOffset = Random().nextDouble() * pi * 2;

  @override
  Vector2 update(double dt, Vector2 selfPos, Vector2 targetPos, double dist) {
    _waveTimer += dt;
    final baseDir = (targetPos - selfPos).normalized();
    final perpendicular = Vector2(-baseDir.y, baseDir.x);
    final wave = sin(_waveTimer * 3.0 + _waveOffset) * 0.6;
    return (baseDir + perpendicular * wave).normalized();
  }
}

/// AI 3: Golem - very slow but tanky
class GolemAI implements EnemyAI {
  @override
  Vector2 update(double dt, Vector2 selfPos, Vector2 targetPos, double dist) {
    return (targetPos - selfPos).normalized();
  }
}

/// AI 4: Spitter - keeps distance
class SpitterAI implements EnemyAI {
  static const _keepDistance = 180.0;
  double _shootCooldown = 3.0;

  bool get canShoot => _shootCooldown <= 0;
  void resetShootCooldown() => _shootCooldown = 3.0;

  @override
  Vector2 update(double dt, Vector2 selfPos, Vector2 targetPos, double dist) {
    _shootCooldown -= dt;
    final toTarget = (targetPos - selfPos).normalized();

    if (dist < _keepDistance - 20) {
      return -toTarget;
    } else if (dist > _keepDistance + 20) {
      return toTarget;
    }
    return Vector2.zero();
  }
}

/// AI 5: Charger - wind up then charge
class ChargerAI implements EnemyAI {
  static const _chargeRange = 200.0;
  static const _chargeWindupTime = 1.0;
  static const _chargeSpeed = 5.0;

  _ChargerState _state = _ChargerState.patrol;
  double _windupTimer = 0;
  Vector2 _chargeDir = Vector2.zero();

  bool get isCharging => _state == _ChargerState.charging;

  @override
  Vector2 update(double dt, Vector2 selfPos, Vector2 targetPos, double dist) {
    switch (_state) {
      case _ChargerState.patrol:
        if (dist < _chargeRange) {
          _state = _ChargerState.windup;
          _windupTimer = _chargeWindupTime;
          _chargeDir = (targetPos - selfPos).normalized();
        }
        return (targetPos - selfPos).normalized() * 0.3;

      case _ChargerState.windup:
        _windupTimer -= dt;
        if (_windupTimer <= 0) {
          _state = _ChargerState.charging;
        }
        return Vector2.zero();

      case _ChargerState.charging:
        return _chargeDir * _chargeSpeed;
    }
  }

  void onHitWall() {
    if (_state == _ChargerState.charging) {
      _state = _ChargerState.patrol;
    }
  }
}

enum _ChargerState { patrol, windup, charging }

// =================================================================
// Enemy entity classes
// =================================================================

abstract class EnemyComponent extends GameEntityComponent {
  late final EnemyAI ai;
  double _attackCooldown = 0;

  bool get canAttack => _attackCooldown <= 0;
  void resetAttackCooldown() => _attackCooldown = 1.0 / stats.attackSpeed;

  EnemyComponent({
    required super.entityId,
    required super.baseStats,
    super.position,
    super.size,
  }) : super(anchor: Anchor.center);

  @override
  bool get showHpBar => true;

  Vector2 getAIDirection(double dt, Vector2 targetPos) {
    return ai.update(dt, position, targetPos,
        position.distanceTo(targetPos));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_attackCooldown > 0) {
      _attackCooldown -= dt;
    }
  }
}

/// Slime enemy
class SlimeEnemy extends EnemyComponent {
  SlimeEnemy({super.position})
      : super(
          entityId: 'slime_${DateTime.now().microsecondsSinceEpoch}',
          baseStats: DataManager.getEnemyBaseStats('slime'),
          size: Vector2(36, 36),
        ) {
    ai = SlimeAI();
  }

  @override
  Color get entityColor => Colors.green.shade300;

  @override
  String? get spritePath => 'entities/enemies/slime.png';
}

/// Bat enemy
class BatEnemy extends EnemyComponent {
  BatEnemy({super.position})
      : super(
          entityId: 'bat_${DateTime.now().microsecondsSinceEpoch}',
          baseStats: DataManager.getEnemyBaseStats('bat'),
          size: Vector2(32, 28),
        ) {
    ai = BatAI();
  }

  @override
  Color get entityColor => Colors.purple.shade400;

  @override
  String? get spritePath => 'entities/enemies/bat.png';
}

/// Golem enemy
class GolemEnemy extends EnemyComponent {
  GolemEnemy({super.position})
      : super(
          entityId: 'golem_${DateTime.now().microsecondsSinceEpoch}',
          baseStats: DataManager.getEnemyBaseStats('golem'),
          size: Vector2(56, 56),
        ) {
    ai = GolemAI();
  }

  @override
  Color get entityColor => Colors.grey.shade600;

  @override
  String? get spritePath => 'entities/enemies/golem.png';
}

/// Spitter enemy
class SpitterEnemy extends EnemyComponent {
  SpitterEnemy({super.position})
      : super(
          entityId: 'spitter_${DateTime.now().microsecondsSinceEpoch}',
          baseStats: DataManager.getEnemyBaseStats('spitter'),
          size: Vector2(38, 38),
        ) {
    ai = SpitterAI();
  }

  @override
  Color get entityColor => Colors.lime.shade700;

  @override
  String? get spritePath => 'entities/enemies/spitter.png';
}

/// Charger enemy
class ChargerEnemy extends EnemyComponent {
  ChargerEnemy({super.position})
      : super(
          entityId: 'charger_${DateTime.now().microsecondsSinceEpoch}',
          baseStats: DataManager.getEnemyBaseStats('charger'),
          size: Vector2(44, 44),
        ) {
    ai = ChargerAI();
  }

  @override
  Color get entityColor => Colors.red.shade700;

  @override
  String? get spritePath => 'entities/enemies/charger.png';
}

/// Enemy factory - spawns enemies based on wave difficulty
class EnemyFactory {
  static final _random = Random();

  static EnemyComponent spawn(int waveNumber, {Vector2? position}) {
    final pos = position ?? Vector2(
      _random.nextDouble() * 300 - 150,
      _random.nextDouble() * 500 - 250,
    );

    final roll = _random.nextDouble();
    final golemThreshold = (waveNumber / 20.0).clamp(0, 0.15);
    final chargerThreshold = golemThreshold + (waveNumber / 15.0).clamp(0, 0.2);

    if (roll < golemThreshold) return GolemEnemy(position: pos);
    if (roll < chargerThreshold) return ChargerEnemy(position: pos);
    if (roll < 0.4) return BatEnemy(position: pos);
    if (roll < 0.65) return SpitterEnemy(position: pos);
    return SlimeEnemy(position: pos);
  }
}
