import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/i18n/app_localizations.dart';

/// Tutorial overlay shown on first gameplay
/// Displays step-by-step hints about controls and game mechanics
class TutorialOverlay extends StatefulWidget {
  final Locale locale;
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.locale,
    required this.onComplete,
  });

  /// Check if tutorial has been seen before
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('tutorial_completed') ?? false);
  }

  /// Mark tutorial as completed
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<_TutorialStep> _getSteps(S s) => [
        _TutorialStep(
          icon: Icons.gamepad,
          title: s.t('tut_joystick_title'),
          desc: s.t('tut_joystick_desc'),
          position: _StepPosition.bottomLeft,
        ),
        _TutorialStep(
          icon: Icons.auto_fix_high,
          title: s.t('tut_attack_title'),
          desc: s.t('tut_attack_desc'),
          position: _StepPosition.center,
        ),
        _TutorialStep(
          icon: Icons.timer,
          title: s.t('tut_wave_title'),
          desc: s.t('tut_wave_desc'),
          position: _StepPosition.topCenter,
        ),
        _TutorialStep(
          icon: Icons.shopping_cart,
          title: s.t('tut_shop_title'),
          desc: s.t('tut_shop_desc'),
          position: _StepPosition.center,
        ),
        _TutorialStep(
          icon: Icons.star,
          title: s.t('tut_augment_title'),
          desc: s.t('tut_augment_desc'),
          position: _StepPosition.center,
        ),
      ];

  void _nextStep() async {
    final steps = _getSteps(S(widget.locale));
    if (_step < steps.length - 1) {
      await _fadeCtrl.reverse();
      setState(() => _step++);
      _fadeCtrl.forward();
    } else {
      await TutorialOverlay.markCompleted();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(widget.locale);
    final steps = _getSteps(s);
    final step = steps[_step];

    return GestureDetector(
      onTap: _nextStep,
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Stack(
              children: [
                // Step indicator
                Positioned(
                  top: 16,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_step + 1}/${steps.length}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Skip button
                Positioned(
                  top: 16,
                  left: 20,
                  child: GestureDetector(
                    onTap: () async {
                      await TutorialOverlay.markCompleted();
                      widget.onComplete();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s.t('skip'),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                // Content card
                _buildStepContent(step, s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(_TutorialStep step, S s) {
    final alignment = switch (step.position) {
      _StepPosition.topCenter => Alignment.topCenter,
      _StepPosition.center => Alignment.center,
      _StepPosition.bottomLeft => const Alignment(-0.5, 0.6),
    };

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: GameColors.surfaceDark.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: GameColors.accentGold.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: GameColors.accentGold.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GameColors.accentGold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, color: GameColors.accentGold, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.t('tap_to_continue'),
                style: TextStyle(
                  color: GameColors.accentGold.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String desc;
  final _StepPosition position;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.desc,
    required this.position,
  });
}

enum _StepPosition { topCenter, center, bottomLeft }
