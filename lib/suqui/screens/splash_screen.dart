import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';            // ← nuevo
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
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CrazyLogo(),
                const SizedBox(height: 16),
                Text(
                  "Más que control, tranquilidad universitaria.",
                  style: GoogleFonts.uncialAntiqua(           // ← aquí cambias la fuente
                    textStyle: Theme.of(context).textTheme.headlineLarge,
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
