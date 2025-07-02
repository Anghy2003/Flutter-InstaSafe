import 'dart:math';
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

  final List<List<Color>> _colorPalettes = [
    [Color(0xFF07294D), Color(0xFF14141F)],
    [Color(0xFF0A2E55), Color(0xFF1A1A2C)],
    [Color(0xFF103B66), Color(0xFF1F1F30)],
    [Color(0xFF0C2440), Color(0xFF181827)],
    [Color(0xFF05182D), Color(0xFF10101A)],
  ];

  late List<Color> _currentColors;
  late List<Color> _nextColors;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _currentColors = _colorPalettes[random.nextInt(_colorPalettes.length)];
    _nextColors = _colorPalettes[random.nextInt(_colorPalettes.length)];

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _currentColors = _nextColors;
          _nextColors = _colorPalettes[Random().nextInt(_colorPalettes.length)];
          _controller.forward(from: 0.0);
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _interpolateColors(List<Color> a, List<Color> b, double t) {
    return List.generate(
      min(a.length, b.length),
      (i) => Color.lerp(a[i], b[i], t) ?? a[i],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double angle = _controller.value * 2 * pi;
    final double t = _controller.value;
    final double pulse = 0.5 + 0.4 * sin(angle); // 0.1 - 0.9

    final colors = _interpolateColors(_currentColors, _nextColors, t)
        .map((c) => c.withOpacity(pulse.clamp(0.2, 0.95)))
        .toList();

    return Stack(
      children: [
        // Capa 1: fondo base
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(cos(angle), sin(angle)),
              radius: 1.6 + 0.2 * sin(angle * 2),
              colors: colors,
              stops: const [0.3, 1.0],
            ),
          ),
        ),
        // Capa 2: rotación opuesta con distinto radio
        Opacity(
          opacity: 0.4,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-cos(angle * 1.2), -sin(angle * 1.5)),
                radius: 1.2 + 0.1 * cos(angle * 3),
                colors: colors.reversed.toList(),
                stops: const [0.2, 1.0],
              ),
            ),
          ),
        ),
        // Capa 3: pulso lento, centrado
        Opacity(
          opacity: 0.2 + 0.3 * sin(angle * 0.5),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.8 + 0.2 * cos(angle * 0.8),
                colors: [
                  colors[0].withOpacity(0.5),
                  colors[1].withOpacity(0.0),
                ],
                stops: const [0.1, 1.0],
              ),
            ),
          ),
        ),
        // Contenido hijo
        widget.child,
      ],
    );
  }
}
