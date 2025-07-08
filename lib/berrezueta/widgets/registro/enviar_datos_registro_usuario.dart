import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
}) async {
  try {
    final uri = Uri.parse('http://192.168.56.48:8090/api/usuarios');
    final request = http.MultipartRequest('POST', uri);

    request.fields['cedula'] = cedula;
    request.fields['nombre'] = nombre;
    request.fields['apellido'] = apellido;
    request.fields['correo'] = correo;
    request.fields['genero'] = genero;
    request.fields['idresponsable'] = idResponsable.toString();
    request.fields['fechanacimiento'] = fechaNacimiento.toIso8601String();
    request.fields['contrasena'] = contrasena;
    request.fields['id_rol'] = idRol.toString();

    final bytes = await imagen.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'biometrico',
      bytes,
      filename: 'rostro.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return 'ok';
    } else {
      final error = await response.stream.bytesToString();
      return 'Servidor respondió con error: $error';
    }
  } catch (e) {
    return 'Excepción de conexión: $e';
  }
}