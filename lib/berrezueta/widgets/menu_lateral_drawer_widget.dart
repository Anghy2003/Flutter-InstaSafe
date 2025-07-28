import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';

class DrawerMenuLateral extends StatelessWidget {
  const DrawerMenuLateral({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int rol = UsuarioActual.idRol ?? 0;
    final placeholder = const AssetImage(
      'assets/avatar_placeholder.png',
    ) as ImageProvider;

    // Determinar imagen a mostrar:
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

    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(-1.0, 0), end: Offset.zero),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, offset, child) {
        return FractionalTranslation(
          translation: offset,
          child: child,
        );
      },
      child: Drawer(
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: DegradadoFondoScreen(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                  color: const Color(0xFF0E1D33),
                  child: Column(
                    children: [
                      // Avatar circular con borde
                      Container(
                        width: 105,
                        height: 105,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: (105 - 6) / 2, // 6 = 2 * border width
                          backgroundImage: avatarImage,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${UsuarioActual.nombre ?? ''} ${UsuarioActual.apellido ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _separadorTurquesa(),
                        _buildMenuItem(
                          context,
                          Icons.history,
                          'Historial',
                          '/historial',
                        ),
                        _buildMenuItem(
                          context,
                          Icons.person,
                          'Perfil',
                          '/perfil',
                        ),
                        if ([1, 2, 5].contains(rol))
                          _buildMenuItem(
                            context,
                            Icons.qr_code_scanner,
                            'Control de acceso',
                            '/escaneo',
                          ),
                        if (rol == 1 || rol == 5)
                          _buildMenuItem(
                            context,
                            Icons.person_add,
                            'Registrar Usuario',
                            '/registro',
                          ),
                        _buildMenuItem(
                          context,
                          Icons.logout,
                          'Salir',
                          '/login',
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _separadorTurquesa() {
    return Container(
      height: 1,
      width: double.infinity,
      color: const Color.fromRGBO(8, 66, 92, 1),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.white, size: 22),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            trailing:
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () {
              Navigator.pop(context);
              context.go(route);
            },
            hoverColor: Colors.white.withOpacity(0.1),
            splashColor: Colors.white.withOpacity(0.2),
          ),
          _separadorTurquesa(),
        ],
      ),
    );
  }
}
