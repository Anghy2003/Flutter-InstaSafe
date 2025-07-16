import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:instasafe/illescas/screens/faceplus_service.dart';
import 'package:instasafe/models/plantillafacial.dart';
import 'package:instasafe/illescas/screens/usuarioLigero.dart';
import 'package:instasafe/illescas/screens/comparadorfacial_ligero.dart';
import 'package:instasafe/berrezueta/widgets/registro/subir_imagen_drive.dart';
import 'package:instasafe/utils/UtilImagen.dart';
Future<String> enviarDatosRegistroUsuario({
  required String cedula,
  required String nombre,
  required String apellido,
  required String correo,
  required String genero,
  required int idResponsable,
  required DateTime fechaNacimiento,
  required String contrasena,
  required int idRol,
  required File imagen,
  required String accessToken,
  required String carpetaDriveId,
  required String plantillaFacialBase64,
  required String plantillaFacial,
}) async {
  try {
    print('🔐 Iniciando envío de datos para $cedula');

    final plantillaNueva = PlantillaFacial.fromBase64(plantillaFacialBase64);
    print('✅ Plantilla facial decodificada');

    // 1️⃣ Obtener plantillas existentes
    print('📡 Consultando plantillas existentes del backend...');
    final t1 = DateTime.now();
    final response = await http.get(
      Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas'),
    );
    print('⏱️ Tiempo consulta plantillas: ${DateTime.now().difference(t1).inMilliseconds} ms');

    if (response.statusCode != 200) {
      print('❌ Error HTTP ${response.statusCode} al obtener plantillas');
      return '❌ Error al obtener plantillas existentes: ${response.statusCode}';
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final usuarios = jsonList.map((e) => UsuarioLigero.fromJson(e)).toList();
    print('📦 Plantillas obtenidas: ${usuarios.length}');

    // 2️⃣ Verificación local
    print('🔎 Verificando coincidencia local...');
    final resultadoLocal = ComparadorFacialLigero.comparar(plantillaNueva, usuarios);
    if (resultadoLocal != null) {
      final usuarioLocal = resultadoLocal['usuario'];
      final distancia = resultadoLocal['distancia'].toStringAsFixed(3);
      print('⚠ Coincidencia local con ${usuarioLocal.cedula} (distancia: $distancia)');
    } else {
      print('✅ No se detectó coincidencia local directa');
    }

    // 3️⃣ Subir imagen a Cloudinary
    print('🖼️ Redimensionando imagen para Cloudinary...');
    final imagenReducida = await UtilImagen.reducirImagen(imagen);
    print('📤 Subiendo imagen a Cloudinary...');
    final t2 = DateTime.now();
    final urlCloudinary = await UtilImagen.subirACloudinary(imagenReducida);
    print('⏱️ Tiempo subida Cloudinary: ${DateTime.now().difference(t2).inMilliseconds} ms');

    if (urlCloudinary == null) {
      print('❌ Falló la subida a Cloudinary');
      return '❌ Error al subir imagen a Cloudinary';
    }
    print('✅ Imagen subida a Cloudinary: $urlCloudinary');

    // 5️⃣ Subir imagen a Google Drive
    print('📤 Subiendo imagen a Drive...');
    final t3 = DateTime.now();
    final fotoUrl = await subirImagenADrive(imagen, accessToken, carpetaDriveId);
    print('⏱️ Tiempo subida Drive: ${DateTime.now().difference(t3).inMilliseconds} ms');

    if (fotoUrl == null) {
      print('❌ Falló la subida a Drive');
      return '❌ Error al subir imagen a Drive';
    }
    print('✅ Imagen subida a Drive: $fotoUrl');

    // 6️⃣ Registrar rostro en Face++
    print('😶 Registrando rostro en Face++...');
    final t4 = DateTime.now();
    final exitoFaceRegistro = await FacePlusService.registrarFaceDesdeUrl(urlCloudinary, cedula);
    print('⏱️ Tiempo Face++: ${DateTime.now().difference(t4).inMilliseconds} ms');

    if (!exitoFaceRegistro) {
      print('❌ Falló registro de rostro en Face++');
      return '❌ No se pudo registrar rostro en Face++';
    }
    print('✅ Rostro registrado en Face++');

    // 7️⃣ Registrar usuario en backend
    print('🧾 Registrando usuario en backend...');
    final uri = Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios');
    final t5 = DateTime.now();
    final registroResponse = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'genero': genero,
        'idresponsable': idResponsable.toString(),
        'fechanacimiento': fechaNacimiento.toIso8601String(),
        'contrasena': contrasena,
        'id_rol': idRol.toString(),
        'foto': fotoUrl,
        'plantillaFacial': plantillaFacialBase64,
      },
    );
    print('⏱️ Tiempo POST usuario: ${DateTime.now().difference(t5).inMilliseconds} ms');

    if (registroResponse.statusCode == 200 || registroResponse.statusCode == 201) {
      print('✅ Usuario registrado correctamente en backend');
      return 'ok';
    } else {
      print('❌ Error al registrar usuario: ${registroResponse.body}');
      return 'Servidor respondió con error: ${registroResponse.body}';
    }
  } catch (e) {
    print('❌ Excepción en enviarDatosRegistroUsuario: $e');
    return 'Excepción de conexión: $e';
  }
}
