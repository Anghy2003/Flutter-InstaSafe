import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instasafe/suqui/theme/animated.dart';
import 'package:instasafe/suqui/widgets/crazy_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Ocupa todo el espacio sobrante y centra el logo
              const Expanded(
                child: Center(
                  child: CrazyLogo(),
                ),
              ),

              // Frase descriptiva debajo del logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Tu campus, tu seguridad, nuestra misión.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: ancho * 0.05,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Copyright abajo
              Text(
                '© IstaSafe',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: ancho * 0.033,
                      color: Colors.white70,
                    ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
