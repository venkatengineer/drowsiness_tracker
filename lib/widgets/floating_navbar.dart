import 'dart:ui';

import 'package:flutter/material.dart';

class FloatingNavBarItem {
  const FloatingNavBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<FloatingNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.white).withValues(
                alpha: isDark ? 0.10 : 0.70,
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.80),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = index == currentIndex;
                return Expanded(
                  child: Tooltip(
                    message: item.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.30),
                                    blurRadius: 22,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              color: selected
                                  ? primary
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              child: selected
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        item.label,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
