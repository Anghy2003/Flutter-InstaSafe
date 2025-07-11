import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:instasafe/illescas/screens/usuarioLigero.dart';

import 'package:instasafe/models/plantillafacial.dart';

import 'package:instasafe/models/generadorplantilla.dart';
import 'package:instasafe/illescas/screens/comparadorfacial_ligero.dart';
import 'package:instasafe/illescas/screens/verificar.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';

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
  final mounted = context.mounted;
  try {
    final picker = ImagePicker();

    // Mostrar loader inicial
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 📸 Forzar cámara trasera
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    Navigator.of(context).pop(); // Cerrar loader

    if (pickedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se tomó ninguna foto.')),
        );
      }
      return;
    }

    final generador = GeneradorPlantillaFacial();
    await generador.inicializarModelo();

    // Mostrar loader de procesamiento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final plantillaBase64 =
        await generador.generarDesdeImagen(File(pickedFile.path));

    Navigator.of(context).pop(); // Cerrar loader

    if (plantillaBase64 == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ No se detectó ningún rostro válido.')),
        );
      }
      return;
    }

    final plantillaCapturada = PlantillaFacial.fromBase64(plantillaBase64);

    // Obtener lista de plantillas desde el backend
    final response = await http.get(
      Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas'),
    );

    if (response.statusCode != 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al obtener plantillas (${response.statusCode})')),
        );
      }
      return;
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final usuarios = jsonList.map((e) => UsuarioLigero.fromJson(e)).toList();

    final resultado = ComparadorFacialLigero.comparar(plantillaCapturada, usuarios);

    if (!mounted) return;

    if (resultado != null) {
      final usuario = resultado['usuario'] as UsuarioLigero;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificacionResultadoScreen(datosUsuario: {
            'cedula': usuario.cedula,
            'mensaje': '✅ Acceso permitido',
          }),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('😕 No se encontró coincidencia.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop(); // Por si quedó algún loader abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error inesperado: $e')),
      );
    }
  }
}

}
