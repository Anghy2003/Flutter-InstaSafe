import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instasafe/illescas/screens/CamaraGuiadaScreen%20.dart';
import 'package:instasafe/illescas/screens/QrScannerScreen.dart';
import 'package:instasafe/illescas/screens/faceplus_service.dart';
import 'package:instasafe/illescas/screens/usuarioLigero.dart';
import 'package:instasafe/models/plantillafacial.dart';
import 'package:instasafe/models/generadorplantilla.dart';
import 'package:instasafe/illescas/screens/comparadorfacial_ligero.dart';
import 'package:instasafe/illescas/screens/verificar.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';
import 'package:instasafe/utils/UtilImagen.dart';

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
            children: [
              const SizedBox(height: 60),
              Icon(Icons.qr_code_2_rounded, size: ancho * 0.65, color: Colors.white),
              const SizedBox(height: 40),
              _botonOpcion(
                context,
                icon: Icons.qr_code_scanner_rounded,
                titulo: "ESCANEAR QR",
                subtitulo: "Escanea un código QR",
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
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
              Text('©IstaSafe', style: TextStyle(color: Colors.white.withOpacity(0.6))),
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
                Text(titulo,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitulo,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
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
    File? fotoTomada;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CamaraGuiadaScreen(onFotoCapturada: (foto) => fotoTomada = foto),
      ),
    );

    if (fotoTomada == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se tomó ninguna foto.')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 🔍 Generar plantilla facial
    final generador = GeneradorPlantillaFacial();
    await generador.inicializarModelo();
    final resultadoGeneracion = await generador.generarDesdeImagen(fotoTomada!);
    final plantillaBase64 = resultadoGeneracion['plantilla'];

    PlantillaFacial? plantillaCapturada;
    if (plantillaBase64 != null) {
      plantillaCapturada = PlantillaFacial.fromBase64(plantillaBase64);
    }

    // 👤 Comparación local (opcional)
    List<UsuarioLigero> usuarios = [];
    try {
      final response = await http.get(
        Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas'),
      );
      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        usuarios = jsonList.map((e) => UsuarioLigero.fromJson(e)).toList();
      }
    } catch (_) {}

    final resultadoLocal = plantillaCapturada != null
        ? ComparadorFacialLigero.comparar(plantillaCapturada, usuarios)
        : null;

    if (resultadoLocal != null) {
      print('⚠ Coincidencia local: ${resultadoLocal['usuario']?.cedula}');
    }

    // ☁️ Subir a Cloudinary
    final imagenReducida = await UtilImagen.reducirImagen(fotoTomada!);
    final urlCloudinary = await UtilImagen.subirACloudinary(imagenReducida);

    // 🔍 Verificar en Face++
    final resultadoFacePlus = await FacePlusService.verificarFaceDesdeUrl(urlCloudinary ?? '');
    Navigator.of(context).pop(); // Cerrar loader

    if (!mounted) return;

    if (resultadoFacePlus != null) {
      final cedulaDetectada = resultadoFacePlus['user_id']?.toString();

      if (cedulaDetectada == null || cedulaDetectada.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ El rostro no tiene una cédula asociada en Face++.')),
        );
        return;
      }

      // 📥 Obtener datos del usuario por cédula
      final response = await http.get(
        Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/cedula/$cedulaDetectada'),
      );

      if (response.statusCode == 200) {
        final usuario = jsonDecode(response.body);

        final datosUsuario = {
          'id': usuario['id'],
          'nombre': '${usuario['nombre']} ${usuario['apellido']}',
          'email': usuario['correo'] ?? '',
          'rol': usuario['id_rol']?['nombre'] ?? 'Desconocido',
          'foto': usuario['foto'],
          'cedula': usuario['cedula'],
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificacionResultadoScreen(
              datosUsuario: datosUsuario,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Usuario no encontrado en la base de datos')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('😕 No se encontró coincidencia con Face++')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error inesperado: $e')),
      );
    }
  }
}


}
