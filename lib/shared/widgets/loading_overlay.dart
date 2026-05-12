import 'package:flutter/material.dart';

/// 載入覆蓋層元件
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool visible;
  final Widget? child;

  const LoadingOverlay({
    super.key,
    this.message,
    this.visible = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ?child,
        if (visible)
          AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48, height: 48,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(message!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
