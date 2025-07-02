import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DrawerMenuLateral extends StatelessWidget {
  const DrawerMenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(color: Colors.white, fontSize: 16);

    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF07294D)),
            child: Center(
              child: Text(
                'Menú',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: Text('Historial', style: estilo),
            onTap: () => context.go('/historial'),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: Text('Perfil', style: estilo),
            onTap: () => context.go('/perfil'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner, color: Colors.white),
            title: Text('Escanear QR', style: estilo),
            onTap: () => context.go('/escaneo'),
          ),
          ListTile(
            leading: const Icon(Icons.person_add, color: Colors.white),
            title: Text('Registrar Usuario', style: estilo),
            onTap: () => context.go('/registro'),
          ),
          const Spacer(),
          Divider(color: Colors.grey[600]),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: Text('Salir', style: estilo),
            onTap: () => context.go('/'),
          ),
        ],
      ),
    );
  }
}