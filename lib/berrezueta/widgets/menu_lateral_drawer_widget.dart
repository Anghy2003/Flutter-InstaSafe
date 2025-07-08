// main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyHomePage(),
    ),
    GoRoute(
      path: '/historial',
      builder: (context, state) => const SimplePage(title: 'Historial'),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const SimplePage(title: 'Perfil'),
    ),
    GoRoute(
      path: '/escaneo',
      builder: (context, state) => const SimplePage(title: 'Escanear QR'),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const SimplePage(title: 'Registrar Usuario'),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        brightness: Brightness.dark,
      ),
      routerConfig: _router,
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      drawer: const DrawerMenuLateral(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07294D),
        title: const Text('Inicio'),
      ),
      body: const Center(
        child: Text(
          'Bienvenido',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;
  const SimplePage({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07294D),
        title: Text(title),
      ),
      drawer: const DrawerMenuLateral(),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

class DrawerMenuLateral extends StatelessWidget {
  const DrawerMenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    final estilo = const TextStyle(color: Colors.white, fontSize: 16);

    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF07294D)),
            child: Center(
              child: Text('Menú', style: TextStyle(fontSize: 20, color: Colors.white)),
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