import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/models/auditoria_models.dart';
import 'package:instasafe/berrezueta/services/auditoria_service.dart';
import 'package:instasafe/illescas/screens/faceplus_service.dart';
import 'package:instasafe/models/plantillafacial.dart';
import 'package:instasafe/illescas/screens/usuarioLigero.dart';
import 'package:instasafe/illescas/screens/comparadorfacial_ligero.dart';
import 'package:instasafe/berrezueta/widgets/registro/subir_imagen_drive.dart';
import 'package:instasafe/utils/UtilImagen.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
Future<Map<String, dynamic>> enviarDatosRegistroVisitante({
  required String nombre,
  required String apellido,
  required int idRol,
  required File imagen,
  required String carpetaDriveId,
  required String plantillaFacialBase64,
  required String plantillaFacial,
}) async {
  int visitanteId = -1;

  try {
    print('🔐 Iniciando envío de datos para visitante $nombre $apellido');

    final plantillaNueva = PlantillaFacial.fromBase64(plantillaFacialBase64);
    print('✅ Plantilla facial decodificada');

    // Comparación local (opcional)
    try {
      print('🔎 Verificando coincidencia local…');
      final respPlant = await http
          .get(Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas'))
          .timeout(const Duration(seconds: 10));
      if (respPlant.statusCode == 200) {
        final jsonList = jsonDecode(respPlant.body) as List<dynamic>;
        final usuarios = jsonList.map((e) => UsuarioLigero.fromJson(e)).toList();
        final resultadoLocal = ComparadorFacialLigero.comparar(plantillaNueva, usuarios);
        if (resultadoLocal != null) {
          final usuarioLocal = resultadoLocal['usuario'] as UsuarioLigero;
          final distancia = (resultadoLocal['distancia'] as double).toStringAsFixed(3);
          print('⚠ Coincidencia local con ${usuarioLocal.cedula} (distancia $distancia)');
        } else {
          print('✅ No se detectó coincidencia local');
        }
      }
    } catch (e) {
      print('⚠️ Error en comparación local: $e');
    }

    // Subir a Cloudinary
    print('🖼️ Redimensionando imagen…');
    final imagenReducida = await UtilImagen.reducirImagen(imagen);
    print('📤 Subiendo a Cloudinary…');
    final urlCloudinary = await UtilImagen.subirACloudinary(imagenReducida)
        .timeout(const Duration(seconds: 20));
    if (urlCloudinary == null) {
      return {'ok': false, 'error': '❌ Error al subir a Cloudinary'};
    }

    // Subir a Drive
    print('📤 Subiendo imagen original a Drive…');
    final fotoUrl = await subirImagenADrive(imagen, carpetaDriveId)
        .timeout(const Duration(seconds: 20));
    if (fotoUrl == null) {
      return {'ok': false, 'error': '❌ Error al subir imagen a Drive'};
    }

    // Crear visitante en backend
    print('🧾 Creando visitante en backend…');
    final respCreate = await http.post(
      Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/visitantes'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'nombre': nombre,
        'apellido': apellido,
        'id_rol': idRol.toString(),
        'foto': fotoUrl,
        'plantillaFacial': plantillaFacialBase64,
        'token': '', // ← se actualizará después
      },
    ).timeout(const Duration(seconds: 15));

    if (respCreate.statusCode != 200 && respCreate.statusCode != 201) {
      print('❌ Error backend: ${respCreate.body}');
      return {'ok': false, 'error': '❌ Error backend: ${respCreate.body}'};
    }

    final created = jsonDecode(respCreate.body) as Map<String, dynamic>;
    visitanteId = (created['id'] as num).toInt();
    print('✅ Visitante creado con ID $visitanteId');

    // Registrar rostro en Face++
    print('😶 Registrando rostro en Face++...');
    final resultadoFace = await FacePlusService
        .registrarFaceDesdeUrl(urlCloudinary, visitanteId.toString())
        .timeout(const Duration(seconds: 15));

    if (resultadoFace == null || resultadoFace['face_token'] == null) {
      print('❌ No se pudo registrar rostro en Face++');
      await http.delete(
        Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/$visitanteId'),
      );
      return {'ok': false, 'error': '❌ Registro facial fallido'};
    }

    final faceToken = resultadoFace['face_token'];
    print('✅ Rostro registrado en Face++ con token: $faceToken');

    // Auditoría
    if (UsuarioActual.id != null) {
      final evento = "Se registró visitante: $nombre $apellido";
      final auditoria = Auditoria(
        evento: evento,
        descripcion: EventoAuditoria.visitanteRegistrado,
        idUsuario: UsuarioActual.id!,
      );
      await AuditoriaService.registrarAuditoria(auditoria);
      print('📝 Auditoría registrada');
    }

    return {
      'ok': true,
      'visitante': created,
    };
  } on TimeoutException catch (te) {
    if (visitanteId > 0) {
      await http.delete(Uri.parse(
        'https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/$visitanteId',
      ));
    }
    return {'ok': false, 'error': '⌛ Timeout: ${te.message}'};
  } catch (e) {
    if (visitanteId > 0) {
      await http.delete(Uri.parse(
        'https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/$visitanteId',
      ));
    }
    return {'ok': false, 'error': '❌ Error inesperado: $e'};
  }
}
