import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Visual effects system (Flame Components)
/// Provides screen shake, hit particles, death explosions, and XP orbs.
/// All effects are self-removing after completion.

// =================================================================
// Screen Shake Effect
// =================================================================

/// Attaches to camera viewport to shake on damage taken
class ScreenShakeEffect extends Component {
  final double intensity;
  final double duration;
  double _timer = 0;
  final _random = Random();

  ScreenShakeEffect({
    this.intensity = 4.0,
    this.duration = 0.3,
  });

  @override
  void update(double dt) {
    _timer += dt;
    final posParent = parent;
    if (posParent is! PositionComponent) {
      removeFromParent();
      return;
    }

    if (_timer >= duration) {
      posParent.position = Vector2.zero();
      removeFromParent();
      return;
    }

    final progress = 1 - (_timer / duration);
    final offsetX = (_random.nextDouble() - 0.5) * 2 * intensity * progress;
    final offsetY = (_random.nextDouble() - 0.5) * 2 * intensity * progress;
    posParent.position = Vector2(offsetX, offsetY);
  }
}

// =================================================================
// Hit Spark Particles
// =================================================================

/// Spawns small spark particles at hit position
class HitSparkEffect extends PositionComponent {
  final Color color;
  final int particleCount;

  HitSparkEffect({
    required super.position,
    this.color = Colors.white,
    this.particleCount = 8,
  });

  @override
  Future<void> onLoad() async {
    final rng = Random();

    final particle = Particle.generate(
      count: particleCount,
      lifespan: 0.4,
      generator: (i) {
        final angle = rng.nextDouble() * 2 * pi;
        final speed = 60.0 + rng.nextDouble() * 80;
        final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);
        final size = 2.0 + rng.nextDouble() * 3;

        return AcceleratedParticle(
          speed: velocity,
          acceleration: Vector2(0, 120), // Gravity
          child: CircleParticle(
            radius: size,
            paint: Paint()..color = color.withValues(alpha: 0.8),
          ),
        );
      },
    );

    add(ParticleSystemComponent(particle: particle));

    // Self-remove after particle lifetime
    add(RemoveEffect(delay: 0.5));
  }
}

// =================================================================
// Death Explosion Particles
// =================================================================

/// Larger explosion on enemy death - colored fragments
class DeathExplosionEffect extends PositionComponent {
  final Color entityColor;
  final double entitySize;

  DeathExplosionEffect({
    required super.position,
    this.entityColor = Colors.red,
    this.entitySize = 48,
  });

  @override
  Future<void> onLoad() async {
    final rng = Random();
    final fragmentCount = 12 + rng.nextInt(6);

    final particle = Particle.generate(
      count: fragmentCount,
      lifespan: 0.6,
      generator: (i) {
        final angle = rng.nextDouble() * 2 * pi;
        final speed = 40.0 + rng.nextDouble() * 120;
        final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);
        final size = 3.0 + rng.nextDouble() * 5;
        final shade = HSLColor.fromColor(entityColor)
            .withLightness(
                (0.3 + rng.nextDouble() * 0.4).clamp(0.0, 1.0))
            .toColor();

        return AcceleratedParticle(
          speed: velocity,
          acceleration: Vector2(0, 80),
          child: CircleParticle(
            radius: size,
            paint: Paint()..color = shade.withValues(alpha: 0.9),
          ),
        );
      },
    );

    add(ParticleSystemComponent(particle: particle));
    add(RemoveEffect(delay: 0.7));
  }
}

// =================================================================
// Gold Pickup Effect
// =================================================================

/// Floating "+N G" text that rises and fades
class GoldPickupEffect extends PositionComponent {
  final int amount;
  late final TextComponent _textComponent;
  double _timer = 0;

  GoldPickupEffect({
    required super.position,
    required this.amount,
  });

  @override
  Future<void> onLoad() async {
    _textComponent = TextComponent(
      text: '+$amount G',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
    );

    add(_textComponent);

    // Float upward
    add(MoveEffect.by(
      Vector2(0, -40),
      EffectController(duration: 0.8, curve: Curves.easeOut),
    ));
    add(RemoveEffect(delay: 0.9));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    final progress = (_timer / 0.8).clamp(0.0, 1.0);
    final alpha = 1.0 - progress;
    
    final style = (_textComponent.textRenderer as TextPaint).style;
    _textComponent.textRenderer = TextPaint(
      style: style.copyWith(color: style.color?.withValues(alpha: alpha)),
    );
  }
}

// =================================================================
// Damage Number Effect
// =================================================================

/// Floating damage number that pops up from an entity
class DamageNumberEffect extends PositionComponent {
  final double damage;
  final bool isCrit;
  late final TextComponent _textComponent;
  double _timer = 0;

  DamageNumberEffect({
    required super.position,
    required this.damage,
    this.isCrit = false,
  });

  @override
  Future<void> onLoad() async {
    final rng = Random();
    final offsetX = (rng.nextDouble() - 0.5) * 20;

    _textComponent = TextComponent(
      text: isCrit
          ? '${damage.toStringAsFixed(0)}!'
          : damage.toStringAsFixed(0),
      textRenderer: TextPaint(
        style: TextStyle(
          color: isCrit ? const Color(0xFFFF4444) : Colors.white,
          fontSize: isCrit ? 18.0 : 14.0,
          fontWeight: isCrit ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      anchor: Anchor.center,
    );

    add(_textComponent);

    // Pop up + drift
    add(MoveEffect.by(
      Vector2(offsetX, -35),
      EffectController(duration: 0.6, curve: Curves.easeOutBack),
    ));
    add(RemoveEffect(delay: 1.0));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer > 0.3) {
      final progress = ((_timer - 0.3) / 0.6).clamp(0.0, 1.0);
      final alpha = 1.0 - progress;
      final style = (_textComponent.textRenderer as TextPaint).style;
      _textComponent.textRenderer = TextPaint(
        style: style.copyWith(color: style.color?.withValues(alpha: alpha)),
      );
    }
  }
}

// =================================================================
// Wave Start Banner
// =================================================================

/// Large "WAVE N" text that appears at wave start and fades
class WaveBannerEffect extends PositionComponent {
  final int waveNumber;
  late final TextComponent _textComponent;
  double _timer = 0;

  WaveBannerEffect({
    required this.waveNumber,
    required super.position,
  });

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    _textComponent = TextComponent(
      text: 'WAVE $waveNumber',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          letterSpacing: 6,
        ),
      ),
      anchor: Anchor.center,
    );

    add(_textComponent);

    // Scale in, hold, then fade out
    add(ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(duration: 0.4, curve: Curves.easeOutBack),
    ));
    add(RemoveEffect(delay: 2.5));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer > 1.5) {
      final progress = ((_timer - 1.5) / 0.5).clamp(0.0, 1.0);
      final alpha = 1.0 - progress;
      final style = (_textComponent.textRenderer as TextPaint).style;
      _textComponent.textRenderer = TextPaint(
        style: style.copyWith(color: style.color?.withValues(alpha: alpha)),
      );
    }
  }
}

// =================================================================
// Combat Weapon Effects
// =================================================================

/// Quick sword slash animation
class SlashEffect extends PositionComponent {
  final double radius;
  final double attackAngle;
  final Color color;

  SlashEffect({
    required super.position,
    required this.radius,
    required this.attackAngle,
    this.color = Colors.white,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final rect = RectangleComponent(
      size: Vector2(radius, 6),
      paint: Paint()..color = color,
      anchor: Anchor.centerLeft,
    );
    rect.position = Vector2.zero();
    rect.angle = attackAngle - pi / 3;
    add(rect);

    rect.add(RotateEffect.by(
      pi / 1.5,
      EffectController(duration: 0.15, curve: Curves.easeOut),
    ));
    
    // Fade out manually since OpacityEffect can be problematic
    add(TimerComponent(
      period: 0.15,
      onTick: () => removeFromParent(),
      removeOnFinish: true,
    ));
  }
}

/// Projectile that flies to target and triggers callback
class ProjectileEffect extends PositionComponent {
  final PositionComponent target;
  final double speed;
  final Color color;
  final VoidCallback onHit;

  ProjectileEffect({
    required super.position,
    required this.target,
    required this.onHit,
    this.speed = 500.0,
    this.color = Colors.cyanAccent,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleComponent(
      radius: 5,
      paint: Paint()..color = color,
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (target.isRemoving || target.isRemoved) {
      removeFromParent();
      return;
    }
    
    final dir = (target.position - position).normalized();
    position += dir * speed * dt;
    
    if (position.distanceTo(target.position) < 15) {
      onHit();
      removeFromParent();
    }
  }
}
