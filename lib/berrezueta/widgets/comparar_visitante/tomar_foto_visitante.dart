import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/screens/loader_animado_screen.dart';
import 'package:instasafe/illescas/screens/CamaraGuiadaScreen%20.dart';
import 'package:instasafe/illescas/screens/usuarioLigero.dart';
import 'package:instasafe/models/plantillafacial.dart';
import 'package:instasafe/models/generadorplantilla.dart';
import 'package:instasafe/illescas/screens/comparadorfacial_ligero.dart';
import 'package:instasafe/utils/UtilImagen.dart';
import 'package:instasafe/illescas/screens/faceplus_service.dart';
import 'package:instasafe/illescas/screens/verificar.dart';

class TomarFotoVisitanteScreen extends StatefulWidget {
  const TomarFotoVisitanteScreen({super.key});

  @override
  State<TomarFotoVisitanteScreen> createState() => _TomarFotoVisitanteScreenState();
}

class _TomarFotoVisitanteScreenState extends State<TomarFotoVisitanteScreen> {
  @override
  void initState() {
    super.initState();
    // Abre la cámara automáticamente al entrar
    Future.delayed(Duration.zero, () => _tomarYVerificarVisitante(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text("Verificar Visitante"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      body: const Center(
        child: Text(
          "Abriendo cámara...",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}

Future<void> _tomarYVerificarVisitante(BuildContext context) async {
  File? fotoTomada;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          CamaraGuiadaScreen(onFotoCapturada: (foto) => fotoTomada = foto),
    ),
  );

  if (fotoTomada == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se tomó ninguna foto.')),
      );
      // Regresa a la pantalla anterior (EscaneoQRScreen)
      Navigator.of(context).pop();
    }
    return;
  }

  // Loader animado para mensajes
  final mensajeLoader = ValueNotifier<String>("Procesando rostro...");

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => LoaderAnimado(mensajeNotifier: mensajeLoader),
  );
  await Future.microtask(() {});

  try {
    // 1️⃣ Procesamiento facial y generación de plantilla
    mensajeLoader.value = "Procesando rostro...";
    final generador = GeneradorPlantillaFacial();
    await generador.inicializarModelo();
    final resultadoGeneracion = await generador.generarDesdeImagen(fotoTomada!);
    final plantillaBase64 = resultadoGeneracion['plantilla'];

    // 2️⃣ Comparación local SOLO con visitantes
    mensajeLoader.value = "Comparando rostro con visitantes...";
    List<UsuarioLigero> visitantes = [];
    try {
      final response = await http.get(
        Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas-visitantes'),
      );
      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        visitantes = jsonList.map((e) => UsuarioLigero.fromJson(e)).toList();
      }
    } catch (_) {}
    PlantillaFacial? plantillaCapturada;
    if (plantillaBase64 != null) {
      plantillaCapturada = PlantillaFacial.fromBase64(plantillaBase64);
    }
    final resultadoLocal =
        plantillaCapturada != null
            ? ComparadorFacialLigero.comparar(plantillaCapturada, visitantes)
            : null;

    if (resultadoLocal != null) {
      print('⚠ Coincidencia local (visitante): ${resultadoLocal['usuario']?.cedula}');
    }

    // 3️⃣ Subida a Cloudinary
    final imagenReducida = await UtilImagen.reducirImagen(fotoTomada!);
    final urlCloudinary = await UtilImagen.subirACloudinary(imagenReducida);

    // 4️⃣ Consulta en Face++ SOLO visitantes
    mensajeLoader.value = "Verificando rostro en Face++ (visitantes)...";
    final resultadoFacePlus = await FacePlusService.verificarFaceDesdeUrl(
      urlCloudinary ?? '',
    );

    if (context.mounted) Navigator.of(context).pop(); // Cierra el loader
    if (!context.mounted) return;

    if (resultadoFacePlus != null) {
      final idVisitanteDetectado = resultadoFacePlus['user_id']?.toString();

      if (idVisitanteDetectado == null || idVisitanteDetectado.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ El rostro no tiene visitante asociado en Face++.'),
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      // 5️⃣ Descargar datos del visitante
      final response = await http.get(
        Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/$idVisitanteDetectado'),
      );

      if (response.statusCode == 200) {
        final visitante = jsonDecode(response.body);

        final datosVisitante = {
          'id': visitante['id'],
          'nombre': '${visitante['nombre']} ${visitante['apellido']}',
          'email': visitante['correo'] ?? '',
          'rol': 'Visitante',
          'foto': visitante['foto'],
          'cedula': visitante['cedula'] ?? '',
        };

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VerificacionResultadoScreen(datosUsuario: datosVisitante),
          ),
        );
        // Al cerrar la pantalla de resultado, regresar automáticamente a EscaneoQRScreen
        if (context.mounted) Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Visitante no encontrado en la base de datos'),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('😕 No se encontró coincidencia con Face++'),
        ),
      );
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error inesperado: $e')),
      );
      Navigator.of(context).pop();
    }
  }
}
