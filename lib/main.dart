import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'router.dart';
// Agrega la importación del generador
import 'package:instasafe/models/generadorplantilla.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  //  Inicialización del modelo facial SOLO UNA VEZ
  await GeneradorPlantillaFacial().inicializarModelo();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached) {
      // Cierra sesion de Google al cerrar la app
      await GoogleSignIn().signOut();
      UsuarioActual.limpiar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
      title: 'Mi App',
      routerConfig: appRouter,
    );
  }
}
