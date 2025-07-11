import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color.fromARGB(255, 18, 22, 36),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
    ),
  );

  static const RadialGradient backgroundGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [
      Color.fromARGB(255, 18, 22, 36), // color en el centro
      Color.fromARGB(255, 9, 36, 67),  // color a media distancia
      Color.fromARGB(255, 18, 22, 36), // color en el borde
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
