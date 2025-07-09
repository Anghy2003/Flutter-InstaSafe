import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/widgets/menuPrincipal/boton_iniciar_sesion_google.dart';
import 'package:intl/intl.dart';

import '../widgets/menuPrincipal/tarjeta_boton_menu_principal.dart';
import '../widgets/degradado_fondo_screen.dart';

class MenuPrincipalScreen extends StatelessWidget {
  final String nombreUsuario = 'Angie';

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

    final tarjetas = [
      TarjetaBotonMenuPrincipal(
        icono: Icons.qr_code_scanner,
        titulo: 'Escanear QR',
        onPressed: () => context.push('/escaneo'),
      ),
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
      TarjetaBotonMenuPrincipal(
        icono: Icons.person_add_alt,
        titulo: 'Registrar Usuario',
        onPressed: () => context.push('/registro'),
      ),
      TarjetaBotonMenuPrincipal(
        icono: Icons.logout,
        titulo: 'Cerrar Sesion',
        onPressed: () => context.go('/'),
      ),
    ];

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
                  backgroundImage: const NetworkImage(
                    'https://eduv.tecazuay.edu.ec/pluginfile.php/40622/user/icon/academi/f1?rev=594406',
                  ),
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
                  'Último ingreso: 08:42 AM',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: tamanoTextoFecha,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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