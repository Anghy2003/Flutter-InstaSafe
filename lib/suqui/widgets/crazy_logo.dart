import 'package:flutter/material.dart';

class CrazyLogo extends StatefulWidget {
  const CrazyLogo({super.key});

  @override
  State<CrazyLogo> createState() => _CrazyLogoState();
}

class _CrazyLogoState extends State<CrazyLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.2, end: 1.1).animate(
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
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Image.asset(
        'assets/image/logo_istasafe4.jpg',
        height: 200,
        fit: BoxFit.contain,
      ),
    );
  }
}
