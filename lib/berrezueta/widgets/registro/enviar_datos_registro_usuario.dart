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

    // 1️⃣ Decodificar la plantilla Base64
    final plantillaNueva = PlantillaFacial.fromBase64(plantillaFacialBase64);
    print('✅ Plantilla facial decodificada');

    // 2️⃣ Obtener plantillas existentes (timeout 10s)
    print('📡 Consultando plantillas existentes del backend...');
    final respPlant = await http
        .get(Uri.parse(
            'https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas'))
        .timeout(const Duration(seconds: 10));
    if (respPlant.statusCode != 200) {
      return '❌ Error al obtener plantillas: ${respPlant.statusCode}';
    }
    final List<dynamic> jsonList = jsonDecode(respPlant.body);
    print('📦 Plantillas obtenidas: ${jsonList.length}');

    // 3️⃣ Comparación local (sin compute)
    print('🔎 Verificando coincidencia local...');
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
      final distancia =
          (resultadoLocal['distancia'] as double).toStringAsFixed(3);
      print(
          '⚠ Coincidencia local con ${usuarioLocal.cedula} (distancia: $distancia)');
    } else {
      print('✅ No se detectó coincidencia local directa');
    }

    // 4️⃣ Redimensionar + subir a Cloudinary (timeout 20s)
    print('🖼️ Redimensionando imagen para Cloudinary...');
    final imagenReducida = await UtilImagen.reducirImagen(imagen);
    print('📤 Subiendo imagen a Cloudinary...');
    final urlCloudinary = await UtilImagen
        .subirACloudinary(imagenReducida)
        .timeout(const Duration(seconds: 20));
    if (urlCloudinary == null) {
      return '❌ Error al subir imagen a Cloudinary';
    }
    print('✅ Imagen subida a Cloudinary: $urlCloudinary');

    // 5️⃣ Subir imagen a Drive (timeout 20s)
    print('📤 Subiendo imagen a Drive...');
    final fotoUrl = await subirImagenADrive(imagen, carpetaDriveId)
        .timeout(const Duration(seconds: 20));
    if (fotoUrl == null) {
      return '❌ Error al subir imagen a Drive';
    }
    print('✅ Imagen subida a Drive: $fotoUrl');

    // 6️⃣ Registrar rostro en Face++ (timeout 15s)
    print('😶 Registrando rostro en Face++...');
    final exitoFaceRegistro = await FacePlusService
        .registrarFaceDesdeUrl(urlCloudinary, cedula)
        .timeout(const Duration(seconds: 15));
    if (!exitoFaceRegistro) {
      return '❌ No se pudo registrar rostro en Face++';
    }
    print('✅ Rostro registrado en Face++');

    // 7️⃣ Registrar usuario en backend (timeout 15s)
    print('🧾 Registrando usuario en backend...');
    final registroResponse = await http
        .post(
          Uri.parse(
              'https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios'),
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
          },
        )
        .timeout(const Duration(seconds: 15));

    if (registroResponse.statusCode == 200 ||
        registroResponse.statusCode == 201) {
      print('✅ Usuario registrado en backend');

      // === AUDITORIA: Registrar evento ===
      try {
        if (UsuarioActual.id != null) {
          final evento = "Se registró al usuario: $cedula $nombre $apellido";
          final auditoria = Auditoria(
            evento: evento, // <<----- evento = el mensaje completo
            descripcion: EventoAuditoria.usuarioRegistrado, // <<---- descripcion = el código
            idUsuario: UsuarioActual.id!,
          );
          await AuditoriaService.registrarAuditoria(auditoria);
          print('📝 Auditoría registrada con éxito');
        } else {
          print('⚠️ Usuario actual no tiene ID (no se registra auditoría)');
        }
      } catch (e) {
        print('⚠️ No se pudo guardar la auditoría: $e');
      }

      return 'ok';
    } else {
      return '❌ Error backend: ${registroResponse.body}';
    }
  } on TimeoutException catch (te) {
    print('⌛ Timeout en operación: ${te.message}');
    return '⌛ Timeout: ${te.message}';
  } catch (e) {
    print('❌ Excepción en enviarDatosRegistroUsuario: $e');
    return '❌ Error inesperado: $e';
  }
}
