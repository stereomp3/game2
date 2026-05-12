import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../domain/status_effect_system.dart';
import '../domain/weapon_system.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/data/data_manager.dart';
import 'game_entity_component.dart';

/// Player character base class
abstract class PlayerComponent extends GameEntityComponent {
  final String characterId;
  List<double> weaponCooldowns = List.filled(6, 0.0);

  PlayerComponent({
    required this.characterId,
    required super.baseStats,
    super.position,
  }) : super(
          entityId: 'player_$characterId',
          size: Vector2(48, 48),
          anchor: Anchor.center,
        );

  @override
  Color get entityColor => Colors.blue.shade400;

  @override
  void update(double dt) {
    super.update(dt);
    for (int i = 0; i < weaponCooldowns.length; i++) {
      if (weaponCooldowns[i] > 0) {
        weaponCooldowns[i] -= dt;
      }
    }
  }

  // Not used directly anymore, handled by _updatePlayerAttack in SurvivalGameWorld
  bool tryAttack() {
    setEntityState(EntityState.attack);
    return true;
  }

  @override
  Future<PositionComponent> buildVisualBody() async {
    return PlayerVisualComponent(characterId: characterId, size: size);
  }

  void onAttack(GameEntityComponent target);

  PlayerVisualComponent get playerVisual => visualBody as PlayerVisualComponent;

  void updateWeapons(List<WeaponData?> weapons) {
    if (visualBody is PlayerVisualComponent) {
      playerVisual.updateWeapons(weapons);
    }
  }

  // Predefined positions for up to 6 weapons based on user diagram
  static final List<Vector2> weaponSlots = [
    Vector2(25, -20),  // 1: Top Right
    Vector2(-25, -20), // 2: Top Left
    Vector2(35, 5),    // 3: Right
    Vector2(-35, 5),   // 4: Left
    Vector2(20, 30),   // 5: Bottom Right
    Vector2(-20, 30),  // 6: Bottom Left
  ];

  @override
  void resetVisualState() {
    if (visualBody is! PlayerVisualComponent) {
      super.resetVisualState();
      return;
    }
    visualBody.angle = 0;
    visualBody.position = size / 2;
    visualBody.scale = Vector2(1, 1);

    final headBaseY = -12.0;
    final bodyBaseY = 8.0;

    playerVisual.body.angle = 0;
    playerVisual.body.position = playerVisual.size / 2 + Vector2(0, bodyBaseY);
    playerVisual.body.scale = Vector2(facingDirection, 1.0);

    playerVisual.head.angle = 0;
    playerVisual.head.position = playerVisual.size / 2 + Vector2(0, headBaseY);
    playerVisual.head.scale = Vector2(facingDirection, 1.0);
  }

  @override
  void animateIdle(double dt) {
    if (visualBody is! PlayerVisualComponent) {
      super.animateIdle(dt);
      return;
    }
    final cycle = GameConstants.idleBreathCycle;
    final breathScale = 1.0 + sin(animTimer * (2 * pi / cycle)) * 0.02;
    final headBob = sin(animTimer * (2 * pi / cycle)) * 2.0;

    final headBaseY = -12.0;
    final bodyBaseY = 8.0;

    playerVisual.body.scale = Vector2(facingDirection, breathScale);
    playerVisual.body.position = playerVisual.size / 2 + Vector2(0, bodyBaseY);
    playerVisual.body.angle = 0;

    playerVisual.head.scale = Vector2(facingDirection, 1.0);
    playerVisual.head.position = playerVisual.size / 2 + Vector2(0, headBaseY + headBob);
    playerVisual.head.angle = 0;

    // Make weapons breathe
    for (int i = 0; i < playerVisual.weaponContainer.children.length; i++) {
      final weapon = playerVisual.weaponContainer.children.elementAt(i) as PositionComponent;
      final weaponBob = sin(animTimer * (2 * pi / cycle) + i) * 1.5;
      final basePos = weaponSlots[i % weaponSlots.length];
      weapon.position = playerVisual.size / 2 + basePos + Vector2(0, weaponBob);
    }
  }

  @override
  void animateMove(double dt) {
    if (visualBody is! PlayerVisualComponent) {
      super.animateMove(dt);
      return;
    }
    final cycle = GameConstants.walkBobbingCycle;
    final bounceY = (sin(animTimer * (2 * pi / cycle / 2)) * 3.0).abs();
    final bodyTilt = sin(animTimer * (2 * pi / cycle)) * 0.1;

    final headBaseY = -12.0;
    final bodyBaseY = 8.0;

    playerVisual.body.angle = bodyTilt;
    playerVisual.body.position = playerVisual.size / 2 + Vector2(0, bodyBaseY - bounceY);
    playerVisual.body.scale = Vector2(facingDirection, 1.0);

    playerVisual.head.angle = bodyTilt * 0.5;
    playerVisual.head.position = playerVisual.size / 2 + Vector2(0, headBaseY - bounceY);
    playerVisual.head.scale = Vector2(facingDirection, 1.0);

    // Make weapons bounce with movement
    for (int i = 0; i < playerVisual.weaponContainer.children.length; i++) {
      final weapon = playerVisual.weaponContainer.children.elementAt(i) as PositionComponent;
      final basePos = weaponSlots[i];
      weapon.position = playerVisual.size / 2 + basePos - Vector2(0, bounceY);
    }
  }

  @override
  void animateAttack(double dt) {
    if (visualBody is! PlayerVisualComponent) {
      super.animateAttack(dt);
      return;
    }
    // 不要讓頭跟身體有攻擊的抖動動畫，只維持呼吸感即可
    animateIdle(dt);
  }
}

// =================================================================
// Character 1: The Novice
// =================================================================
class NovicePlayer extends PlayerComponent {
  NovicePlayer({super.position})
      : super(
          characterId: 'novice',
          baseStats: DataManager.characters['novice']!,
        );

  @override
  Color get entityColor => Colors.amber.shade600;

  @override
  String? get spritePath => 'entities/players/novice.png';

  @override
  void onAttack(GameEntityComponent target) {
    final dmg = stats.meleeDmg;
    target.takeDamage(dmg);
  }
}

// =================================================================
// Character 2: The Pyromaniac
// =================================================================
class PyromaniacPlayer extends PlayerComponent {
  final _rng = Random();

  PyromaniacPlayer({super.position})
      : super(
          characterId: 'pyromaniac',
          baseStats: DataManager.characters['pyromaniac']!,
        );

  @override
  Color get entityColor => Colors.orange.shade700;

  @override
  String? get spritePath => 'entities/players/pyromaniac.png';

  @override
  void onAttack(GameEntityComponent target) {
    final dmg = stats.elementalDmg * 1.5;
    target.takeDamage(dmg);

    if (_rng.nextDouble() < 0.20) {
      target.statusEffects.applyEffect(
        const StatusEffect(
          type: StatusEffectType.burn,
          duration: 4.0,
          magnitude: 5.0,
        ),
        durationMultiplier: stats.debuffDuration,
      );
    }
  }
}

// =================================================================
// Character 3: The Ninja
// =================================================================
class NinjaPlayer extends PlayerComponent {
  NinjaPlayer({super.position})
      : super(
          characterId: 'ninja',
          baseStats: DataManager.characters['ninja']!,
        );

  @override
  Color get entityColor => Colors.cyan.shade700;

  @override
  String? get spritePath => 'entities/players/ninja.png';

  @override
  void onAttack(GameEntityComponent target) {
    final dmg = stats.applyCrit(stats.meleeDmg);
    target.takeDamage(dmg);
    target.statusEffects.applyEffect(
      const StatusEffect(
          type: StatusEffectType.bleed, duration: 3.0, magnitude: 2.0),
    );
  }
}

// =================================================================
// Character 4: The Tank
// =================================================================
class TankPlayer extends PlayerComponent {
  TankPlayer({super.position})
      : super(
          characterId: 'tank',
          baseStats: DataManager.characters['tank']!,
        );

  @override
  Color get entityColor => Colors.blueGrey.shade600;

  @override
  String? get spritePath => 'entities/players/tank.png';

  @override
  void onAttack(GameEntityComponent target) {
    final dmg = stats.meleeDmg;
    target.takeDamage(dmg);
  }
}

// =================================================================
// Character 5: The Alchemist
// =================================================================
class AlchemistPlayer extends PlayerComponent {
  AlchemistPlayer({super.position})
      : super(
          characterId: 'alchemist',
          baseStats: DataManager.characters['alchemist']!,
        );

  @override
  Color get entityColor => Colors.green.shade700;

  @override
  String? get spritePath => 'entities/players/alchemist.png';

  @override
  void onAttack(GameEntityComponent target) {
    final dmg = stats.rangedDmg;
    target.takeDamage(dmg);
    target.statusEffects.applyEffect(
      const StatusEffect(
        type: StatusEffectType.poison,
        duration: 5.0,
        magnitude: 3.0,
      ),
      durationMultiplier: stats.debuffDuration,
    );
  }
}

/// Player factory function
PlayerComponent createPlayer(String characterId, {Vector2? position}) {
  final pos = position ?? Vector2(200, 300);
  switch (characterId) {
    case 'novice':
      return NovicePlayer(position: pos);
    case 'pyromaniac':
      return PyromaniacPlayer(position: pos);
    case 'ninja':
      return NinjaPlayer(position: pos);
    case 'tank':
      return TankPlayer(position: pos);
    case 'alchemist':
      return AlchemistPlayer(position: pos);
    default:
      return NovicePlayer(position: pos);
  }
}

// =================================================================
// Visual Components for Multi-Part Player
// =================================================================

class PlayerVisualComponent extends PositionComponent {
  final String characterId;
  late PositionComponent head;
  late PositionComponent body;
  late PositionComponent weaponContainer;

  PlayerVisualComponent({required this.characterId, required super.size}) {
    anchor = Anchor.center;
    position = size / 2;
  }

  @override
  Future<void> onLoad() async {
    // Body
    try {
      final bodySprite = await Sprite.load('entities/players/$characterId/body.png');
      body = SpriteComponent(
        sprite: bodySprite,
        size: Vector2(24, 24),
        anchor: Anchor.center,
        position: size / 2 + Vector2(0, 8),
      );
    } catch (_) {
      body = RectangleComponent(
        size: size,
        paint: Paint()..color = Colors.blue.shade400,
        anchor: Anchor.center,
        position: size / 2,
      );
    }

    // Head
    try {
      final headSprite = await Sprite.load('entities/players/$characterId/head.png');
      head = SpriteComponent(
        sprite: headSprite,
        size: Vector2(32, 32),
        anchor: Anchor.center,
        position: size / 2 + Vector2(0, -12),
      );
    } catch (_) {
      head = RectangleComponent(
        size: size * 0.6,
        paint: Paint()..color = Colors.blue.shade200,
        anchor: Anchor.center,
        position: size / 2 + Vector2(0, -10),
      );
    }

    weaponContainer = PositionComponent(
      size: size,
      position: size / 2,
      anchor: Anchor.center,
    );

    await addAll([body, head, weaponContainer]);
  }

  void updateWeapons(List<WeaponData?> weapons) {
    weaponContainer.removeAll(weaponContainer.children);
    final validWeapons = weapons.whereType<WeaponData>().toList();
    if (validWeapons.isEmpty) return;

    final count = validWeapons.length;

    for (int i = 0; i < count; i++) {
      // Get precalculated fixed slot coordinates
      final basePos = PlayerComponent.weaponSlots[i % PlayerComponent.weaponSlots.length];
      
      final weaponComp = WeaponVisualComponent(
        weapon: validWeapons[i],
        position: size / 2 + basePos,
      );
      weaponContainer.add(weaponComp);
    }
  }
}

class WeaponVisualComponent extends PositionComponent {
  final WeaponData weapon;
  
  WeaponVisualComponent({required this.weapon, required super.position}) {
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    final isLeft = position.x < 0;

    try {
      // Try loading weapon sprite
      final sprite = await Sprite.load('weapons/${weapon.baseId}.png');
      add(SpriteComponent(
        sprite: sprite,
        size: Vector2(24, 24),
        anchor: Anchor.center,
      ));
    } catch (_) {
      // Fallback: just use the hand
      try {
        final handSprite = await Sprite.load('entities/players/weapon/hand.png');
        add(SpriteComponent(
          sprite: handSprite,
          size: Vector2(20, 20),
          anchor: Anchor.center,
        ));
      } catch (_) {
        add(CircleComponent(
          radius: 8,
          paint: Paint()..color = Colors.amber.shade200,
          anchor: Anchor.center,
        ));
      }
    }

    if (isLeft) {
      scale = Vector2(-1, 1);
    }
  }

  void swing() {
    final effect = SequenceEffect([
      RotateEffect.by(
        -pi / 4,
        EffectController(duration: 0.1, curve: Curves.easeOut),
      ),
      RotateEffect.by(
        pi / 2,
        EffectController(duration: 0.15, curve: Curves.easeInOut),
      ),
      RotateEffect.by(
        -pi / 4,
        EffectController(duration: 0.15, curve: Curves.easeIn),
      ),
    ]);
    add(effect);
  }
}
