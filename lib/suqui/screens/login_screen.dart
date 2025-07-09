import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/widgets/menuPrincipal/boton_iniciar_sesion_google.dart'; // 👈 importa tu botón

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pantalla Login',
              style: TextStyle(
                fontSize: ancho * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            const BotonIniciarSesionGoogle(),
            const SizedBox(height: 12),
            Text(
              '©IstaSafe',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: ancho * 0.033,
              ),
            ),
          ],
        ),
      ),
    );
  }
}