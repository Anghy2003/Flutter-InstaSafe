import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:intl/intl.dart';
import '../widgets/menuPrincipal/tarjeta_boton_menu_principal.dart';
import '../widgets/degradado_fondo_screen.dart';

class MenuPrincipalScreen extends StatelessWidget {
  final String nombreUsuario = UsuarioActual.nombre ?? 'Usuario';

  String _obtenerFecha() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE, d MMM yyyy', 'es_ES');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final alto = MediaQuery.of(context).size.height;
    final tamanoTextoSaludo = ancho * 0.06;
    final tamanoTextoFecha = ancho * 0.035;
    final rolId = UsuarioActual.idRol ?? 0;

    final String nombreRol = {
      1: 'Administrador',
      2: 'Guardia',
      3: 'Estudiante',
      4: 'Visitante',
      5: 'Seguridad',
      6: 'Docente',
    }[rolId] ?? 'No registrado';

    final List<TarjetaBotonMenuPrincipal> tarjetas = [];

    if (rolId == 1 || rolId == 5 || rolId == 2) {
    tarjetas.add(
      TarjetaBotonMenuPrincipal(
        icono: Icons.qr_code_scanner,
        titulo: 'Control de acceso',
        onPressed: () => context.push('/escaneo'),
      ),
    );
    }

    if ([1, 2, 3, 5, 6].contains(rolId)) {
      tarjetas.add(
        TarjetaBotonMenuPrincipal(
          icono: Icons.person,
          titulo: 'Mi Perfil',
          onPressed: () => context.push('/perfil'),
        ),
      );
      tarjetas.add(
        TarjetaBotonMenuPrincipal(
          icono: Icons.history,
          titulo: 'Historial',
          onPressed: () => context.push('/historial'),
        ),
      );
    }

    if (rolId == 1 || rolId == 5  || rolId == 2) {
      tarjetas.add(
        TarjetaBotonMenuPrincipal(
          icono: Icons.person_add_alt,
          titulo: 'Registrar Usuario',
          onPressed: () => context.push('/registro'),
        ),
      );
    }

    tarjetas.add(
      TarjetaBotonMenuPrincipal(
        icono: Icons.logout,
        titulo: 'Cerrar Sesión',
        onPressed: () => context.go('/'),
      ),
    );

    final double espacio = 16;
    final double anchoTarjeta = (ancho - espacio * 3) / 2;

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SizedBox(height: alto * 0.02),
                CircleAvatar(
  radius: ancho * 0.18,
  backgroundImage: UsuarioActual.fotoUrl != null
      // Si tenemos URL de la foto de Google la cargamos
      ? NetworkImage(UsuarioActual.fotoUrl!)
      // Si no, uso un asset local (no más placeholder remoto)
      : const AssetImage('assets/image/avatar_placeholder.png')
          as ImageProvider,
),
                SizedBox(height: alto * 0.01),
                Text(
                  '¡Hola, $nombreUsuario!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tamanoTextoSaludo,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                    color: Colors.grey[400],
                    fontSize: tamanoTextoFecha,
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
                          .map((t) => SizedBox(width: anchoTarjeta, child: t))
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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