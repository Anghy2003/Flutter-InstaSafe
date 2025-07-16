import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/screens/informacion_registro_screen.dart';
import 'package:instasafe/berrezueta/screens/menu_principal_screen.dart';
import 'package:instasafe/berrezueta/screens/registro_usuario_screen.dart';
import 'package:instasafe/illescas/screens/escaneo_qr_screen.dart';
import 'package:instasafe/illescas/screens/historial_screen.dart';
import 'package:instasafe/suqui/screens/login_screen.dart';
import 'package:instasafe/suqui/screens/perfil_screen.dart';
import 'package:instasafe/suqui/screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    GoRoute(path: '/menu', builder: (context, state) => MenuPrincipalScreen()),

    GoRoute(
      path: '/historial',
      builder: (context, state) => const HistorialScreen(),
    ),

    GoRoute(
      path: '/informacionRegistro',
      builder: (context, state) {
        final id = state.uri.queryParameters['eventoId'];
        return InformacionRegistroScreen(eventoId: id);
      },
    ),

    GoRoute(path: '/perfil', builder: (context, state) => const PerfilScreen()),

    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegistroUsuarioScreen(),
    ),

    GoRoute(
      path: '/escaneo',
      builder: (context, state) => const EscaneoQRScreen(),
    ),
  ],
);
