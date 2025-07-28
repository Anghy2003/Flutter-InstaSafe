import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import '../widgets/degradado_fondo_screen.dart';
import '../widgets/menuPrincipal/tarjeta_boton_menu_principal.dart';

class MenuPrincipalScreen extends StatefulWidget {
  const MenuPrincipalScreen({super.key});

  @override
  State<MenuPrincipalScreen> createState() => _MenuPrincipalScreenState();
}

class _MenuPrincipalScreenState extends State<MenuPrincipalScreen> {
  bool _cerrandoSesion = false;

  String _obtenerFecha() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE, d MMM yyyy', 'es_ES');
    return formatter.format(now);
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    setState(() => _cerrandoSesion = true);
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    UsuarioActual.limpiar();
    setState(() => _cerrandoSesion = false);
    context.go('/');
  }

  Widget _buildAvatar(double diameter) {
    final placeholder = const AssetImage('assets/image/avatar_placeholder.png')
        as ImageProvider;
    ImageProvider avatarImage;

    if (UsuarioActual.fotoGoogle != null &&
        UsuarioActual.fotoGoogle!.isNotEmpty) {
      avatarImage = NetworkImage(UsuarioActual.fotoGoogle!);
    } else if (UsuarioActual.fotoUrl != null &&
        UsuarioActual.fotoUrl!.isNotEmpty) {
      avatarImage = NetworkImage(UsuarioActual.fotoUrl!);
    } else {
      avatarImage = placeholder;
    }

    return CircleAvatar(
      radius: diameter / 2,
      backgroundImage: avatarImage,
      backgroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final alto = MediaQuery.of(context).size.height;
    final tamanoTextoSaludo = ancho * 0.06;
    final tamanoTextoFecha = ancho * 0.035;
    final rolId = UsuarioActual.idRol ?? 0;

    final nombreRol = {
      1: 'Administrador',
      2: 'Guardia',
      3: 'Estudiante',
      4: 'Personal de Limpieza',
      5: 'Seguridad',
      6: 'Docente',
    }[rolId] ?? 'No registrado';

    final nombreUsuario = UsuarioActual.nombre ?? 'Usuario';

    // tarjetas según el rol
    final List<TarjetaBotonMenuPrincipal> tarjetas = [];
    if ([1, 2, 5].contains(rolId)) {
      tarjetas.add(
        TarjetaBotonMenuPrincipal(
          icono: Icons.qr_code_scanner,
          titulo: 'Control de acceso',
          onPressed: () => context.push('/escaneo'),
        ),
      );
    }
    if ([1, 2, 3, 5, 6, 4].contains(rolId)) {
      tarjetas.addAll([
        TarjetaBotonMenuPrincipal(
          icono: Icons.person,
          titulo: 'Mi Perfil',
          onPressed: () => context.push('/perfil'),
        ),
        TarjetaBotonMenuPrincipal(
          icono: Icons.history,
          titulo: 'Historial',
          onPressed: () => context.push('/historial'),
        ),
      ]);
    }
    if ([1, 5].contains(rolId)) {
      tarjetas.add(
        TarjetaBotonMenuPrincipal(
          icono: Icons.person_add_alt,
          titulo: 'Registrar Usuario',
          onPressed: () => context.push('/registro'),
        ),
      );
    }
    if ([1, 2, 5].contains(rolId)) {
      tarjetas.add(
        TarjetaBotonMenuPrincipal(
          icono: Icons.emoji_people,
          titulo: 'Registrar Visitante',
          onPressed: () => context.push('/visitante'),
        ),
      );
    }

    tarjetas.add(
      TarjetaBotonMenuPrincipal(
        icono: Icons.logout,
        titulo: 'Cerrar Sesión',
        onPressed: _cerrandoSesion ? null : () => _cerrarSesion(context),
        trailing: _cerrandoSesion
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.redAccent,
                ),
              )
            : null,
      ),
    );

    final espacio = 16.0;
    final anchoTarjeta = (ancho - espacio * 3) / 2;
    final avatarDiameter = ancho * 0.36;

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(height: alto * 0.02),
                _buildAvatar(avatarDiameter),
                SizedBox(height: alto * 0.01),
                Text(
                  '¡Hola, $nombreUsuario!',
                  style: TextStyle(
                    fontSize: tamanoTextoSaludo,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: alto * 0.005),
                Text(
                  nombreRol,
                  style: TextStyle(
                    fontSize: tamanoTextoFecha,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[300],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: alto * 0.005),
                Text(
                  _obtenerFecha(),
                  style: TextStyle(
                    fontSize: tamanoTextoFecha,
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: alto * 0.03),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: espacio,
                      runSpacing: espacio,
                      alignment: WrapAlignment.center,
                      children: tarjetas
                          .map((t) => SizedBox(
                                width: anchoTarjeta,
                                child: t,
                              ))
                          .toList(),
                    ),
                  ),
                ),
                Text(
                  '©IstaSafe',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: ancho * 0.033,
                  ),
                ),
                SizedBox(height: alto * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
