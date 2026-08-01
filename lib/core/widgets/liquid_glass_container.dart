import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

/// Reusable Liquid Glass / Frosted Glass container widget featuring
/// real-time backdrop blur, glossy light specular border refraction,
/// and soft glassmorphism depth shadows.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 16.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.2,
    this.boxShadow,
    this.onTap,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppStyles.borderRadiusLarge;
    final effectiveBg = backgroundColor ?? AppColors.glassBackground;
    final effectiveBorder = borderColor ?? AppColors.glassBorder;

    Widget containerContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        gradient: LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: [
            effectiveBg,
            effectiveBg.withValues(alpha: (effectiveBg.a * 0.85).clamp(0.0, 1.0)),
          ],
        ),
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      containerContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius is BorderRadius ? effectiveRadius : AppStyles.borderRadiusLarge,
          child: containerContent,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: boxShadow ?? AppStyles.glassShadow,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: containerContent,
        ),
      ),
    );
  }
}
