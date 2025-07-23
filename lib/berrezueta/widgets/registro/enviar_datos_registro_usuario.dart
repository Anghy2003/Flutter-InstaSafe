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

    // 1️⃣ Decodifica la plantilla
    final plantillaNueva = PlantillaFacial.fromBase64(plantillaFacialBase64);
    print('✅ Plantilla facial decodificada');

    // 2️⃣ (Opcional: compara localmente si lo requieres)
    final tPlantillas = DateTime.now();
    final respPlant = await http
        .get(Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas'))
        .timeout(const Duration(seconds: 10));
    print('Tiempo plantillas: ${DateTime.now().difference(tPlantillas).inMilliseconds} ms');
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
      final distancia =
          (resultadoLocal['distancia'] as double).toStringAsFixed(3);
      print('⚠ Coincidencia local con ${usuarioLocal.cedula} (distancia: $distancia)');
      // Si quieres abortar el registro, puedes retornar aquí.
    } else {
      print('✅ No se detectó coincidencia local directa');
    }

    // 3️⃣ Redimensiona antes de subir (importante para velocidad)
    print('🖼️ Redimensionando imagen para Drive...');
    final tReducir = DateTime.now();
    final imagenReducida = await UtilImagen.reducirImagen(imagen);
    print('Tiempo reducir: ${DateTime.now().difference(tReducir).inMilliseconds} ms');

    // 4️⃣ Sube imagen a Drive
    print('📤 Subiendo imagen a Drive...');
    final tDrive = DateTime.now();
    final fotoUrl = await subirImagenADrive(imagenReducida, carpetaDriveId)
        .timeout(const Duration(seconds: 20));
    print('Tiempo subida Drive: ${DateTime.now().difference(tDrive).inMilliseconds} ms');
    if (fotoUrl == null) {
      return '❌ Error al subir imagen a Drive';
    }
    print('✅ Imagen subida a Drive: $fotoUrl');

    // 5️⃣ Guarda usuario en backend con URL real de foto
    final tRegistro = DateTime.now();
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
          },
        )
        .timeout(const Duration(seconds: 15));
    print('Tiempo registro backend: ${DateTime.now().difference(tRegistro).inMilliseconds} ms');

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

      // 6️⃣ (Opcional) Sube a Cloudinary y Face++ en segundo plano
      Future(() async {
        try {
          print('📤 Subiendo imagen a Cloudinary...');
          final urlCloudinary = await UtilImagen.subirACloudinary(imagenReducida)
              .timeout(const Duration(seconds: 20));
          if (urlCloudinary != null) {
            print('✅ Imagen subida a Cloudinary: $urlCloudinary');

            print('😶 Registrando rostro en Face++...');
            final exitoFaceRegistro = await FacePlusService
                .registrarFaceDesdeUrl(urlCloudinary, cedula)
                .timeout(const Duration(seconds: 15));
            if (!exitoFaceRegistro) {
              print('❌ No se pudo registrar rostro en Face++');
            } else {
              print('✅ Rostro registrado en Face++');
            }
          }
        } catch (e) {
          print('❌ Error en proceso de nube/Face++ en background: $e');
        }
      });

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
