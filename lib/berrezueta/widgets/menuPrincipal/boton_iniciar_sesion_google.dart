import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';

class BotonIniciarSesionGoogle extends StatelessWidget {
  const BotonIniciarSesionGoogle({super.key});

  Future<void> _iniciarSesion(BuildContext context) async {
    final googleSignIn = GoogleSignIn(
      scopes: ['https://www.googleapis.com/auth/drive.file'],
    );

    try {
      await googleSignIn.signOut(); // 👈 Cierra cualquier sesión previa

      final cuenta = await googleSignIn.signIn(); // 👈 Fuerza que el usuario elija cuenta
      final auth = await cuenta?.authentication;
      final accessToken = auth?.accessToken;

      if (accessToken != null) {
        UsuarioActual.accessToken = accessToken;
        UsuarioActual.carpetaDriveId = '1ANmx_dBv3xzzahMEMQSsNG6LiwFI1Xti';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✔ Sesión iniciada con éxito')),
        );

        context.go('/menu'); // ✅ Redirige al menú
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠ No se pudo obtener token')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al iniciar sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.login, color: Colors.white),
      label: const Text(
        'Iniciar sesión con Google',
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
      onPressed: () => _iniciarSesion(context),
    );
  }
}