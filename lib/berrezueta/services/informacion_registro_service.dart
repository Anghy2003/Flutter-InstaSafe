import 'dart:convert';
import 'package:http/http.dart' as http;

class InformacionRegistroService {
  static const String _baseUrl = 'https://spring-instasafe-441403171241.us-central1.run.app/api/eventos';

  /// Obtiene la información detallada de un evento por su ID
  static Future<Map<String, dynamic>?> fetchEventoById(String eventoId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$eventoId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener evento: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al cargar evento: $e');
      rethrow;
    }
  }
}