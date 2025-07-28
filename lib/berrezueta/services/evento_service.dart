import 'dart:convert';
import 'package:http/http.dart' as http;

class EventoService {
  static const _baseUrl = 'https://spring-instasafe-441403171241.us-central1.run.app/api/eventos';

  /// Busca el evento abierto (sin fechaSalida) para el usuario en la fecha de hoy.
  Future<Map<String, dynamic>?> getEventoPendiente(int idUsuario) async {
    final url = '$_baseUrl/pendiente/$idUsuario';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    if (resp.statusCode == 204) {
      return null;
    }
    throw Exception('Error al consultar evento pendiente: ${resp.statusCode}');
  }

  /// Registra ingreso o salida. El backend decide según si hay evento pendiente.

  Future<Map<String, dynamic>> registrarEvento({
  required int idUsuario,
  required int idGuardia,
  String titulo = 'ACCESO',
  String descripcion = '',
  int? idLugar,
}) async {
  final body = {
    'titulo': titulo,
    'descripcion': descripcion,
    'id_usuario': {'id': idUsuario},
    'id_guardia': {'id': idGuardia},
    if (idLugar != null) 'id_lugar': {'id': idLugar}, 
    'fechasalida': null,
  };

  final resp = await http.post(
    Uri.parse(_baseUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (resp.statusCode == 200 || resp.statusCode == 201) {
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
  throw Exception('Error al registrar evento: ${resp.body}');
}

}
