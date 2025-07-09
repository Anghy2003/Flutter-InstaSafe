import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/widgets/registro/subir_imagen_drive.dart'; // 👈 ajusta según tu ruta

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
}) async {
  try {
    final fotoUrl = await subirImagenADrive(imagen, accessToken, carpetaDriveId);

    if (fotoUrl == null) {
      return '❌ Error al subir imagen a Drive';
    }

    print('📤 Enviando datos de usuario con foto: $fotoUrl');

    final uri = Uri.parse('http://192.168.68.122:8090/api/usuarios');
    final request = http.MultipartRequest('POST', uri)
      ..fields['cedula'] = cedula
      ..fields['nombre'] = nombre
      ..fields['apellido'] = apellido
      ..fields['correo'] = correo
      ..fields['genero'] = genero
      ..fields['idresponsable'] = idResponsable.toString()
      ..fields['fechanacimiento'] = fechaNacimiento.toIso8601String()
      ..fields['contrasena'] = contrasena
      ..fields['id_rol'] = idRol.toString()
      ..fields['foto'] = fotoUrl;

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Usuario registrado correctamente');
      return 'ok';
    } else {
      final error = await response.stream.bytesToString();
      print('❌ Error al registrar usuario: $error');
      return 'Servidor respondió con error: $error';
    }
  } catch (e) {
    print('❌ Excepción al registrar usuario: $e');
    return 'Excepción de conexión: $e';
  }
}