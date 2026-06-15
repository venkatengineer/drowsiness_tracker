import 'dart:ui';

import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(22),
    this.margin,
    this.borderRadius = 28,
    this.opacity,
    this.borderOpacity,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? opacity;
  final double? borderOpacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? Colors.white : Colors.white;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: surface.withValues(
                alpha: opacity ?? (isDark ? 0.09 : 0.52),
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: surface.withValues(
                  alpha: borderOpacity ?? (isDark ? 0.16 : 0.72),
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
