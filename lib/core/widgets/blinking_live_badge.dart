import 'package:flutter/material.dart';

/// Animated Blinking LIVE badge with a pulsing dot indicator for Live courses.
class BlinkingLiveBadge extends StatefulWidget {
  final String label;
  final double fontSize;
  final EdgeInsets padding;

  const BlinkingLiveBadge({
    super.key,
    this.label = 'LIVE',
    this.fontSize = 10.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  State<BlinkingLiveBadge> createState() => _BlinkingLiveBadgeState();
}

class _BlinkingLiveBadgeState extends State<BlinkingLiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
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
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626), // Vibrant Red
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.50),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified Badge Renderer for Course Modes: LIVE, RECORDED, BOTH
class CourseModeBadge extends StatelessWidget {
  final String mode;

  const CourseModeBadge({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final modeUpper = mode.toUpperCase();

    if (modeUpper == 'LIVE') {
      return const BlinkingLiveBadge(label: 'LIVE');
    }

    if (modeUpper == 'BOTH') {
      return const BlinkingLiveBadge(label: 'LIVE + RECORDED');
    }

    if (modeUpper == 'RECORDED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7), // Sky Blue
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.40),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.videocam_rounded, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'RECORDED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    // Default regular mode badge
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        modeUpper,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
