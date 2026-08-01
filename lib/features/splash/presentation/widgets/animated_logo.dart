import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// Animated splash component presenting the PME logo & Pawan Mate (Teacher photo).
/// On August 2nd (Pawan Sir's birthday), shows a special birthday wish animation.
class AnimatedLogo extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final bool isBirthday;

  const AnimatedLogo({
    super.key,
    required this.controller,
    this.size = 200.0,
    this.isBirthday = false,
  });

  @override
  Widget build(BuildContext context) {
    // Logo Animations (0.0 to 0.45)
    final Animation<double> logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    final Animation<double> logoScale = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // Teacher Photo & Info Animations (0.25 to 0.80)
    final Animation<double> photoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.25, 0.70, curve: Curves.easeIn),
      ),
    );

    final Animation<double> photoScale = Tween<double>(
      begin: 0.80,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.25, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // Birthday Animations (0.60 to 1.0)
    final Animation<double> birthdayFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOutBack),
      ),
    );

    final Animation<double> birthdayScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.60, 0.90, curve: Curves.elasticOut),
      ),
    );

    // Balloon float animation (continuous oscillation)
    final Animation<double> balloonFloat = Tween<double>(
      begin: -0.15,
      end: 0.15,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.50, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Candle flicker animation
    final Animation<double> candleFlicker = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.70, 1.0, curve: Curves.easeInOut),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // --- Birthday Balloons (only on birthday) ---
              if (isBirthday) ..._buildBirthdayBalloons(balloonFloat),

              // --- Confetti Particles (only on birthday) ---
              if (isBirthday) ..._buildConfetti(birthdayFade),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- 1. App Logo & Brand Header ---
                  FadeTransition(
                    opacity: logoFade,
                    child: ScaleTransition(
                      scale: logoScale,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryLight.withValues(alpha: 0.6),
                            ),
                            child: Image.asset(
                              AppAssets.logo,
                              width: 85.0,
                              height: 85.0,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'PAWAN MATE EDUCATION',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- 2. Teacher Photo & Identity Card ---
                  FadeTransition(
                    opacity: photoFade,
                    child: ScaleTransition(
                      scale: photoScale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Birthday glowing ring (only on birthday)
                          if (isBirthday)
                            Container(
                              width: 175,
                              height: 175,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [
                                    Color(0xFFFF1744),
                                    Color(0xFFFFD740),
                                    Color(0xFF1DE217),
                                    Color(0xFF2196F3),
                                    Color(0xFFFF1744),
                                  ],
                                  startAngle: 0.0,
                                  endAngle: math.pi * 2,
                                  tileMode: TileMode.clamp,
                                ),
                              ),
                              child: Opacity(
                                opacity: birthdayFade.value * 0.8,
                                child: const SizedBox.shrink(),
                              ),
                            ),

                          // Avatar Card with Glowing Ring & Shadow
                          Container(
                            width: 148,
                            height: 148,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.accent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.22),
                                  blurRadius: isBirthday ? 30 * birthdayFade.value : 22,
                                  spreadRadius: isBirthday ? 4 * birthdayFade.value : 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4), // Ring thickness
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: Image.asset(
                                  AppAssets.pawanMate,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),

                          // Birthday Cake Badge (only on birthday)
                          if (isBirthday)
                            Positioned(
                              bottom: -18,
                              child: FadeTransition(
                                opacity: birthdayFade,
                                child: ScaleTransition(
                                  scale: birthdayScale,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF1744),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Animated candle
                                        Container(
                                          width: 10,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD740),
                                            borderRadius: BorderRadius.circular(5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFD740).withValues(alpha: 0.8 * candleFlicker.value),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Teacher Name
                  const Text(
                    'Pawan Mate',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Designation Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.school_rounded,
                          size: 15,
                          color: AppColors.accent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Founder & Lead Educator',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Birthday Wish Text (only on birthday)
                  if (isBirthday)
                    FadeTransition(
                      opacity: birthdayFade,
                      child: ScaleTransition(
                        scale: birthdayScale,
                        child: Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF1744),
                                Color(0xFFFF5252),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF1744).withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Text(
                            '🎉 Happy Birthday Pawan Sir! 🎉',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds floating birthday balloons with oscillation animation.
  List<Widget> _buildBirthdayBalloons(Animation<double> float) {
    final colors = [
      const Color(0xFFFF1744),
      const Color(0xFF2196F3),
      const Color(0xFFFFEB3B),
      const Color(0xFF4CAF50),
      const Color(0xFFE91E63),
      const Color(0xFFFF9800),
    ];

    final positions = [
      const Offset(-120, -80),
      const Offset(130, -60),
      const Offset(-140, 40),
      const Offset(150, 30),
      const Offset(-100, 120),
      const Offset(140, 100),
    ];

    return List.generate(6, (i) {
      final offset = positions[i];
      final scale = 0.8 + (i % 3) * 0.2;
      return Positioned(
        left: offset.dx + 120,
        top: offset.dy + 180,
        child: Transform.translate(
          offset: Offset(0, -float.value * 20 * scale),
          child: Opacity(
            opacity: 0.7 + 0.3 * math.sin(i * 0.5 + controller.value * math.pi * 2),
            child: Container(
              width: 16 * scale,
              height: 20 * scale,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors[i % colors.length].withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Align(
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Builds confetti particles that fade and scale in.
  List<Widget> _buildConfetti(Animation<double> fade) {
    final colors = [
      const Color(0xFFFF1744),
      const Color(0xFFFFEB3B),
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFE91E63),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];

    final random = math.Random(42);
    return List.generate(24, (i) {
      final angle = (i / 24) * math.pi * 2;
      final distance = 100.0 + random.nextDouble() * 40;
      final x = math.cos(angle) * distance;
      final y = math.sin(angle) * distance;
      final size = 4.0 + random.nextDouble() * 4;
      final color = colors[i % colors.length];

      return Positioned(
        left: 120 + x,
        top: 180 + y,
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.3, end: 1.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: Interval(
                  0.60 + (i / 24) * 0.3,
                  0.90 + (i / 24) * 0.1,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: Transform.rotate(
              angle: angle + controller.value * math.pi * 2,
              child: Container(
                width: size,
                height: size * 2.5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(size / 2),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
