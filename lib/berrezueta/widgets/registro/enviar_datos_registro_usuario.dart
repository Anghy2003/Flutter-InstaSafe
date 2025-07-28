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
Future<String> enviarDatosRegistroUsuario({
  required String cedula,
  required String nombre,
  required String apellido,
  required String correo,
  required String genero,
  required DateTime fechaNacimiento,
  required String contrasena,
  required int idRol,
  required File imagen,
  required String carpetaDriveId,
  required String plantillaFacialBase64,
  required String plantillaFacial,
}) async {
  try {
    print('🔐 Iniciando envío de datos para $cedula');

    final plantillaNueva = PlantillaFacial.fromBase64(plantillaFacialBase64);
    print('✅ Plantilla facial decodificada');

    // Comparación local
    final respPlant = await http
        .get(Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas'))
        .timeout(const Duration(seconds: 10));
    if (respPlant.statusCode != 200) {
      return '❌ Error al obtener plantillas: ${respPlant.statusCode}';
    }

    final List<dynamic> jsonList = jsonDecode(respPlant.body);
    Map<String, dynamic>? resultadoLocal;
    try {
      resultadoLocal = ComparadorFacialLigero.comparar(
        plantillaNueva,
        jsonList.map((e) => UsuarioLigero.fromJson(e)).toList(),
      );
    } catch (e) {
      print('⚠️ Error en comparación local: $e');
    }

    if (resultadoLocal != null) {
      final usuarioLocal = resultadoLocal['usuario'] as UsuarioLigero;
      final distancia = (resultadoLocal['distancia'] as double).toStringAsFixed(3);
      print('⚠ Coincidencia local con ${usuarioLocal.cedula} (distancia: $distancia)');
    } else {
      print('✅ No se detectó coincidencia local directa');
    }

    // Reducción de imagen
    final imagenReducida = await UtilImagen.reducirImagen(imagen);

    // Subida a Cloudinary (para Face++)
    print('📤 Subiendo imagen a Cloudinary...');
    final urlCloudinary = await UtilImagen.subirACloudinary(imagenReducida)
        .timeout(const Duration(seconds: 20));
    if (urlCloudinary == null) return '❌ Error al subir a Cloudinary';

    print('😶 Registrando rostro en Face++...');
    final resultadoFace = await FacePlusService
        .registrarFaceDesdeUrl(urlCloudinary, cedula)
        .timeout(const Duration(seconds: 15));

    if (resultadoFace == null) {
      print('❌ Registro facial fallido');
      return '❌ No se pudo registrar rostro en Face++';
    }

    final faceToken = resultadoFace['face_token'] ?? '';
    print('✅ Rostro registrado con token: $faceToken');

    // Subida a Google Drive (para la foto oficial)
    print('📤 Subiendo imagen a Drive...');
    final fotoUrl = await subirImagenADrive(imagenReducida, carpetaDriveId)
        .timeout(const Duration(seconds: 20));
    if (fotoUrl == null) return '❌ Error al subir imagen a Drive';

    // Registro en backend (con token incluido)
    final registroResponse = await http
        .post(
          Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'cedula': cedula,
            'nombre': nombre,
            'apellido': apellido,
            'correo': correo,
            'genero': genero,
            'fechanacimiento': fechaNacimiento.toIso8601String(),
            'contrasena': contrasena,
            'id_rol': idRol.toString(),
            'foto': fotoUrl,
            'plantillaFacial': plantillaFacialBase64,
            'token': faceToken, 
          },
        )
        .timeout(const Duration(seconds: 15));

    if (registroResponse.statusCode == 200 || registroResponse.statusCode == 201) {
      print('✅ Usuario registrado en backend');

      // Auditoría
      if (UsuarioActual.id != null) {
        final evento = "Se registró al usuario: $cedula $nombre $apellido";
        final auditoria = Auditoria(
          evento: evento,
          descripcion: EventoAuditoria.usuarioRegistrado,
          idUsuario: UsuarioActual.id!,
        );
        await AuditoriaService.registrarAuditoria(auditoria);
        print('📝 Auditoría registrada con éxito');
      }

      return 'ok';
    } else {
      return '❌ Error backend: ${registroResponse.body}';
    }
  } on TimeoutException catch (te) {
    return '⌛ Timeout: ${te.message}';
  } catch (e) {
    print('❌ Excepción en enviarDatosRegistroUsuario: $e');
    return '❌ Error inesperado: $e';
  }
}


