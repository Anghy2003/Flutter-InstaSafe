// menu_lateral_drawer_widget.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';

class DrawerMenuLateral extends StatelessWidget {
  const DrawerMenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: DegradadoFondoScreen(
          child: Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.transparent,
            child: Column(
              children: [
                // Header con perfil de usuario
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                  child: Column(
                    children: [
                      // Foto de perfil
                      Container(
                        width: 105,
                        height: 105,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          image: const DecorationImage(
                            image: NetworkImage('https://eduv.tecazuay.edu.ec/pluginfile.php/40622/user/icon/academi/f1?rev=594406'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Nombre del usuario
                      const Text(
                        'Angie Illescas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Opciones del menú
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
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
                      _buildMenuItem(
                        context,
                        Icons.login,
                        'Registrar Ingreso',
                        '/escaneo',
                      ),
                      _buildMenuItem(
                        context,
                        Icons.person_add,
                        'Registrar Usuario',
                        '/registro',
                      ),
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        Icons.logout,
                        'Salir',
                        '/login',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
        hoverColor: Colors.white.withOpacity(0.1),
        splashColor: Colors.white.withOpacity(0.2),
      ),
    );
  }
}