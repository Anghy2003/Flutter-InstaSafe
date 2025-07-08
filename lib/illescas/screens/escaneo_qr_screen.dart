import 'package:flutter/material.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/drawer_widget.dart';

class EscaneoQRScreen extends StatelessWidget {
  const EscaneoQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const DrawerMenuLateral(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Registrar\nIngreso',
            style: TextStyle(
              color: Colors.white,
              fontSize: ancho * 0.05,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Icono QR grande
              Icon(
                Icons.qr_code_2_rounded,
                size: ancho * 0.65,
                color: Colors.white,
              ),
              const SizedBox(height: 40),
              // Botón ESCANEAR QR
              _botonOpcion(
                context,
                icon: Icons.qr_code_scanner_rounded,
                titulo: "ESCANEAR QR",
                subtitulo: "Escanea un código QR",
                onPressed: () {
                  // Lógica para escanear QR
                },
              ),
              const SizedBox(height: 40),
              // Botón TOMAR FOTO
              _botonOpcion(
                context,
                icon: Icons.photo_camera_front_rounded,
                titulo: "TOMAR FOTO",
                subtitulo: "Captura una imagen",
                onPressed: () {
                  // Lógica para tomar foto
                },
              ),
              const Spacer(),
              Text(
                '©IstaSafe',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonOpcion(BuildContext context,
      {required IconData icon,
      required String titulo,
      required String subtitulo,
      required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2240), // Azul oscuro
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blueAccent.shade700),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
