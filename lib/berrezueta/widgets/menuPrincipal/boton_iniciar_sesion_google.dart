import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';

class BotonIniciarSesionGoogle extends StatelessWidget {
  final VoidCallback? onLoadingStart;
  final VoidCallback? onLoadingEnd;

  const BotonIniciarSesionGoogle({
    super.key,
    this.onLoadingStart,
    this.onLoadingEnd,
  });

  Future<void> _iniciarSesion(BuildContext context) async {
    final googleSignIn = GoogleSignIn(
      scopes: ['https://www.googleapis.com/auth/drive.file'],
    );

    try {
      onLoadingStart?.call();
      await googleSignIn.signOut();
      final cuenta = await googleSignIn.signIn();
      final auth = await cuenta?.authentication;
      final accessToken = auth?.accessToken;

      if (accessToken != null && cuenta != null) {
        UsuarioActual.accessToken = accessToken;
        UsuarioActual.carpetaDriveId = '1ANmx_dBv3xzzahMEMQSsNG6LiwFI1Xti';
        UsuarioActual.fotoUrl = cuenta.photoUrl;
        UsuarioActual.correo = cuenta.email;

        final ok = await UsuarioActual.cargarDesdeCorreo(cuenta.email);

        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✔ Sesión iniciada con éxito')),
          );
          context.go('/menu');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠ No se encontró el usuario')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠ No se pudo obtener token')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al iniciar sesión: $e')),
      );
    } finally {
      onLoadingEnd?.call();
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
