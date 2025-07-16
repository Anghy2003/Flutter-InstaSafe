import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({required this.child, super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        // Oscila la parada central entre 0.45 y 0.55
        final midStop = 0.5 + 0.05 * sin(2 * pi * t);
        // Oscila ligeramente el radio del degradado
        final radius = 0.8 + 0.02 * sin(2 * pi * t);

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: radius,
              colors: const [
                Color(0xFF121624),
                Color(0xFF092443),
                Color(0xFF121624),
              ],
              stops: [0.0, midStop, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
