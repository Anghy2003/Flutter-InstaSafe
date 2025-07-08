import 'package:flutter/material.dart';

class DegradadoFondoScreen extends StatefulWidget {
  final Widget child;

  const DegradadoFondoScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<DegradadoFondoScreen> createState() => _DegradadoFondoScreenState();
}

class _DegradadoFondoScreenState extends State<DegradadoFondoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _intensidad;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _intensidad = Tween<double>(begin: 0.3, end: 1.0).animate(
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
      animation: _intensidad,
      builder: (context, child) {
        return ColoredBox( // ✅ Esto evita el parpadeo blanco inicial
          color: const Color(0xFF1A1A2E),
          child: Container(
            decoration: RadialGradientBox(_intensidad.value),
            child: widget.child,
          ),
        );
      },
    );
  }

  // ✅ Extraído para mantener código limpio
  BoxDecoration RadialGradientBox(double intensidad) {
    return BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          Color(0xFF07294D).withOpacity(intensidad),
          const Color.fromARGB(255, 20, 20, 31),
        ],
      ),
    );
  }
}