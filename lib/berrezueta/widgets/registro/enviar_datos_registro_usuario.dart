import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<bool> enviarDatosRegistroUsuario({
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
}) async {
  try {
    final uri = Uri.parse('https://tuservidor.com/api/usuarios'); // 🔁 Reemplaza con tu URL real

    final request = http.MultipartRequest('POST', uri);

    // Campos de texto
    request.fields['cedula'] = cedula;
    request.fields['nombre'] = nombre;
    request.fields['apellido'] = apellido;
    request.fields['correo'] = correo;
    request.fields['genero'] = genero;
    request.fields['idresponsable'] = idResponsable.toString();
    request.fields['fechanacimiento'] = fechaNacimiento.toIso8601String();
    request.fields['contrasena'] = contrasena;
    request.fields['id_rol'] = idRol.toString();

    // Imagen como byte array para biometrico
    final bytes = await imagen.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'biometrico',
      bytes,
      filename: 'rostro.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

    // Enviar la solicitud
    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Registro exitoso');
      return true;
    } else {
      final error = await response.stream.bytesToString();
      print('❌ Error al registrar usuario: $error');
      return false;
    }
  } catch (e) {
    print('⚠️ Excepción: $e');
    return false;
  }
}