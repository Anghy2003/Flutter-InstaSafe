import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/models/usuario_actual.dart';

Future<void> obtenerNombreDesdeCorreo() async {
  final correo = UsuarioActual.correo;
  if (correo == null || correo.isEmpty) return;

  try {
    final response = await http.get(
      Uri.parse('http://192.168.56.31:8090/api/usuarios/correo/$correo'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      UsuarioActual.nombre = data['nombre'] ?? '';
      UsuarioActual.apellido = data['apellido'] ?? '';
    } else {
      // Si no se encuentra, puedes dejar el nombre como desconocido
      UsuarioActual.nombre = 'Desconocido';
      UsuarioActual.apellido = '';
    }
  } catch (e) {
    UsuarioActual.nombre = 'Error';
    UsuarioActual.apellido = '';
  }
}