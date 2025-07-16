import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  /// Devuelve el JSON del usuario o lanza una excepción si falla.
  static Future<Map<String, dynamic>> login(String correo, String clave) async {
    final uri = Uri.parse(
      'https://spring-instasafe-441403171241.us-central1.run.app/api/login'
      '?correo=${Uri.encodeComponent(correo)}'
      '&contrasena=${Uri.encodeComponent(clave)}'
    );
    final resp = await http.post(uri, headers: {'Content-Type':'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('Credenciales inválidas (${resp.statusCode})');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }
}
