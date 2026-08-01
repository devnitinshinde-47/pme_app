import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LiquidGlassNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const LiquidGlassNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Floating Liquid Glass Bottom Navigation Bar with translucent backdrop blur,
/// floating rounded ergonomics, glossy specular edge reflection, and
/// smooth gliding active liquid glass pill indicator.
class LiquidGlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavItem> items;

  const LiquidGlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double bottomInset = mediaQuery.padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomInset > 0 ? bottomInset + 4 : 16,
      ),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.85),
                    Colors.white.withValues(alpha: 0.60),
                  ],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double totalWidth = constraints.maxWidth;
                  final double itemWidth = totalWidth / items.length;

                  return Stack(
                    children: [
                      // Animated Liquid Glass Pill Indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.fastOutSlowIn,
                        left: currentIndex * itemWidth + 4,
                        top: 2,
                        bottom: 2,
                        width: itemWidth - 8,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.14),
                                AppColors.primary.withValues(alpha: 0.07),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.10),
                                blurRadius: 10,
                                spreadRadius: -1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Navigation Items Row
                      Row(
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final isSelected = index == currentIndex;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => onTap(index),
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: isSelected ? 1.12 : 1.0,
                                      duration: const Duration(milliseconds: 250),
                                      child: Icon(
                                        isSelected
                                            ? (item.activeIcon ?? item.icon)
                                            : item.icon,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textMuted,
                                        size: isSelected ? 24 : 22,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 250),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textMuted,
                                        letterSpacing: 0.2,
                                      ),
                                      child: Text(item.label),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
