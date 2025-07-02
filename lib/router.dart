import 'package:go_router/go_router.dart';
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
    GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => MenuPrincipalScreen(),
    ),
    GoRoute(
      path: '/historial',
      builder: (context, state) => HistorialScreen(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => PerfilScreen(),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => RegistroUsuarioScreen(),
    ),
    GoRoute(
      path: '/escaneo',
      builder: (context, state) => EscaneoQRScreen(),
    ),
  ],
);