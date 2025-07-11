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
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _anim = Tween<double>(begin: 0, end: 2 * pi).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        // movemos el centro en un pequeño círculo de radio 0.2
        final x = cos(_anim.value) * 0.2;
        final y = sin(_anim.value) * 0.2;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(x, y),
              radius: 0.8,
              colors: const [
                Color.fromARGB(255, 18, 22, 36),
                Color.fromARGB(255, 9, 36, 67),
                Color.fromARGB(255, 18, 22, 36),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
