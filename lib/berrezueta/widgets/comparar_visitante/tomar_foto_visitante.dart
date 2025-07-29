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
          "Obteniendo información...",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}

Future<void> _tomarYVerificarVisitante(BuildContext context) async {
  File? fotoTomada;

  print('📷 Iniciando flujo de toma de foto...');
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          CamaraGuiadaScreen(onFotoCapturada: (foto) => fotoTomada = foto),
    ),
  );

  if (fotoTomada == null) {
    print('❌ No se tomó ninguna foto');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se tomó ninguna foto.')),
      );
      Navigator.of(context).pop();
    }
    return;
  }

  final mensajeLoader = ValueNotifier<String>("Procesando rostro...");

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => LoaderAnimado(mensajeNotifier: mensajeLoader),
  );
  await Future.microtask(() {}); // permite que se muestre el diálogo antes de continuar

  try {
    print('🧠 Cargando modelo y generando plantilla facial...');
    mensajeLoader.value = "Procesando rostro...";
    final generador = GeneradorPlantillaFacial();
    await generador.inicializarModelo();
    final resultadoGeneracion = await generador.generarDesdeImagen(fotoTomada!);
    final plantillaBase64 = resultadoGeneracion['plantilla'];

    print('🧬 Plantilla generada: ${plantillaBase64 != null ? "✅ OK" : "❌ NULL"}');

    mensajeLoader.value = "Comparando rostro con visitantes...";
    print('🔍 Consultando plantillas de visitantes del backend...');
    List<UsuarioLigero> visitantes = [];
    try {
      final response = await http.get(
        Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas-visitantes'),
      );
      print('🌐 Status visitantes: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        visitantes = jsonList.map((e) => UsuarioLigero.fromJson(e)).toList();
        print('👥 Visitantes obtenidos: ${visitantes.length}');
      }
    } catch (e) {
      print('❌ Error al obtener visitantes: $e');
    }

    PlantillaFacial? plantillaCapturada;
    if (plantillaBase64 != null) {
      plantillaCapturada = PlantillaFacial.fromBase64(plantillaBase64);
    }

    final resultadoLocal = plantillaCapturada != null
        ? ComparadorFacialLigero.comparar(plantillaCapturada, visitantes)
        : null;

    if (resultadoLocal != null) {
      print('⚠ Coincidencia local (visitante): ${resultadoLocal['usuario']?.cedula}');
    } else {
      print('😕 Sin coincidencia local');
    }

    print('🌐 Subiendo imagen a Cloudinary...');
    final imagenReducida = await UtilImagen.reducirImagen(fotoTomada!);
    final urlCloudinary = await UtilImagen.subirACloudinary(imagenReducida);
    print('📸 URL Cloudinary: $urlCloudinary');

    mensajeLoader.value = "Verificando rostro...";
    final resultadoFacePlus = await FacePlusService.verificarFaceDesdeUrl(urlCloudinary ?? '');

    if (context.mounted) Navigator.of(context).pop();
    if (!context.mounted) return;

    if (resultadoFacePlus != null) {
      final idVisitanteDetectado = resultadoFacePlus['user_id']?.toString();
      print('🔍 Visitante detectado en Face++: $idVisitanteDetectado');

      if (idVisitanteDetectado == null || idVisitanteDetectado.isEmpty) {
        print('❌ Coincidencia sin user_id válido');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ El rostro no tiene visitante asociado en Face++.'),
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      final response = await http.get(
        Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/$idVisitanteDetectado'),
      );
      print('🌐 Respuesta datos visitante: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final visitante = jsonDecode(response.body);
          print('📋 Datos visitante: $visitante');

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

          if (context.mounted) Navigator.of(context).pop();
        } catch (e) {
          print('❌ Error al parsear JSON: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no tiene rol de visitante')),
          );
          Navigator.of(context).pop();
        }
      } else {
        print('❌ Visitante no encontrado o sin datos');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no tiene rol de visitante')),
        );
        Navigator.of(context).pop();
      }
    } else {
      print('❌ Sin coincidencia en Face++');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('😕 No se encontró coincidencia con Face++'),
        ),
      );
      Navigator.of(context).pop();
    }
  } catch (e) {
    print('❌ Excepción durante verificación: $e');
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no tiene rol de visitante')),
      );
      Navigator.of(context).pop();
    }
  }
}

