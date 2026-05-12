import 'package:flutter/material.dart';
import '../../core/constants/color_palette.dart';

/// 動畫按鈕元件：按壓縮放效果與光暈動畫
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final double fontSize;
  final IconData? icon;
  final bool enabled;
  final bool showGlow;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.fontSize = 18,
    this.icon,
    this.enabled = true,
    this.showGlow = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btnColor = widget.color ?? GameColors.accentGold;
    final txtColor = widget.textColor ?? GameColors.backgroundDark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => _onTapDown() : null,
        onTapUp: widget.enabled ? (_) => _onTapUp() : null,
        onTapCancel: widget.enabled ? _onTapCancel : null,
        child: AnimatedOpacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.width,
            height: widget.height ?? 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [btnColor, btnColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: btnColor.withValues(
                      alpha: widget.showGlow ? 0.6 : 0.3),
                  blurRadius: widget.showGlow ? 20 : 8,
                  spreadRadius: widget.showGlow ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: txtColor, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: txtColor,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapDown() => _controller.forward();
  void _onTapUp() {
    _controller.reverse();
    widget.onPressed();
  }
  void _onTapCancel() => _controller.reverse();
}
