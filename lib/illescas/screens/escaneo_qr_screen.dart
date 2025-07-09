import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';

import 'package:instasafe/illescas/screens/verificar.dart'; // 👈 Asegúrate de importar

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
              Icon(
                Icons.qr_code_2_rounded,
                size: ancho * 0.65,
                color: Colors.white,
              ),
              const SizedBox(height: 40),
              _botonOpcion(
                context,
                icon: Icons.qr_code_scanner_rounded,
                titulo: "ESCANEAR QR",
                subtitulo: "Escanea un código QR",
                onPressed: () {
                  // Lógica futura para escanear QR
                },
              ),
              const SizedBox(height: 40),
              _botonOpcion(
                context,
                icon: Icons.photo_camera_front_rounded,
                titulo: "TOMAR FOTO",
                subtitulo: "Captura una imagen",
                onPressed: () => tomarFotoYVerificar(context),
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

  Widget _botonOpcion(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2240),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> tomarFotoYVerificar(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se tomó ninguna foto.')),
        );
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      // 🔁 Cambia esta URL por tu IP real y puerto correcto
      final url = Uri.parse('http://192.168.68.122:8090/api/verificacion/facial');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/octet-stream'},
        body: bytes,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificacionResultadoScreen(datosUsuario: jsonData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error del servidor (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al verificar: $e')),
      );
    }
  }
}
