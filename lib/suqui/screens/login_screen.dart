import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/widgets/menuPrincipal/boton_iniciar_sesion_google.dart';
import '../theme/theme.dart'; // Importa tu AppTheme

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;

    return Theme(
      data: AppTheme.lightTheme, // 1️⃣ Inyecta tu tema
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient, // 2️⃣ Fondo degradado
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pantalla Login',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: ancho * 0.05,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const BotonIniciarSesionGoogle(),
                const SizedBox(height: 12),
                Text(
                  '© IstaSafe',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: ancho * 0.033,
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
