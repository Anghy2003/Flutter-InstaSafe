import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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