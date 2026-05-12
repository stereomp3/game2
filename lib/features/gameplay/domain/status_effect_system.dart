
/// Status effect types (Pure Dart enum)
enum StatusEffectType {
  poison,
  burn,
  freeze,
  bleed,
  vulnerable,
  stun,
}

/// Single status effect instance
class StatusEffect {
  final StatusEffectType type;
  final double duration;
  final double magnitude;
  final int stacks;
  final String? sourceId;

  const StatusEffect({
    required this.type,
    required this.duration,
    this.magnitude = 1.0,
    this.stacks = 1,
    this.sourceId,
  });

  StatusEffect copyWith({
    double? duration,
    double? magnitude,
    int? stacks,
  }) {
    return StatusEffect(
      type: type,
      duration: duration ?? this.duration,
      magnitude: magnitude ?? this.magnitude,
      stacks: stacks ?? this.stacks,
      sourceId: sourceId,
    );
  }

  bool get isExpired => duration <= 0;
}

/// Status effect management system (Pure Dart)
class StatusEffectSystem {
  final List<StatusEffect> _effects = [];

  List<StatusEffect> get effects => List.unmodifiable(_effects);

  bool get isFrozen => _hasActive(StatusEffectType.freeze);
  bool get isStunned => _hasActive(StatusEffectType.stun);
  bool get isVulnerable => _hasActive(StatusEffectType.vulnerable);
  bool get isBurning => _hasActive(StatusEffectType.burn);
  bool get isPoisoned => _hasActive(StatusEffectType.poison);

  int get poisonStacks =>
      _effects.where((e) => e.type == StatusEffectType.poison)
          .fold(0, (s, e) => s + e.stacks);

  bool _hasActive(StatusEffectType type) =>
      _effects.any((e) => e.type == type && !e.isExpired);

  void applyEffect(StatusEffect effect, {double durationMultiplier = 1.0}) {
    final adjustedEffect = effect.copyWith(
      duration: effect.duration * durationMultiplier,
    );

    switch (effect.type) {
      case StatusEffectType.poison:
        _effects.add(adjustedEffect);

      case StatusEffectType.burn:
      case StatusEffectType.freeze:
      case StatusEffectType.vulnerable:
      case StatusEffectType.stun:
        final existing = _effects.indexWhere((e) => e.type == effect.type);
        if (existing >= 0) {
          _effects[existing] = adjustedEffect;
        } else {
          _effects.add(adjustedEffect);
        }

      case StatusEffectType.bleed:
        if (poisonStacks < 10) {
          _effects.add(adjustedEffect);
        }
    }
  }

  double tick(double dt, {double effectivenessMultiplier = 1.0}) {
    double totalDamage = 0;

    for (int i = _effects.length - 1; i >= 0; i--) {
      final effect = _effects[i];
      _effects[i] = effect.copyWith(duration: effect.duration - dt);

      switch (effect.type) {
        case StatusEffectType.poison:
          totalDamage +=
              effect.magnitude * effect.stacks * effectivenessMultiplier * dt;
        case StatusEffectType.burn:
          totalDamage += effect.magnitude * effectivenessMultiplier * dt;
        default:
          break;
      }

      if (_effects[i].isExpired) {
        _effects.removeAt(i);
      }
    }

    return totalDamage;
  }

  double calculateBleedDamage(double movementThisFrame) {
    final bleedEffects =
        _effects.where((e) => e.type == StatusEffectType.bleed);
    if (bleedEffects.isEmpty) return 0;
    return bleedEffects.fold(0.0, (s, e) => s + e.magnitude) *
        (movementThisFrame / 50.0);
  }

  void clearAll() => _effects.clear();

  void clearType(StatusEffectType type) =>
      _effects.removeWhere((e) => e.type == type);

  List<StatusEffect> getTransferrableEffects() {
    return _effects
        .where((e) =>
            e.type == StatusEffectType.burn ||
            e.type == StatusEffectType.poison ||
            e.type == StatusEffectType.bleed)
        .map((e) => e.copyWith(duration: e.duration * 0.5))
        .toList();
  }
}
