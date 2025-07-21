import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/models/auditoria_models.dart';

class AuditoriaService {
  static Future<void> registrarAuditoria(Auditoria auditoria) async {
    final url = Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/auditorias');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(auditoria.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al guardar auditoría: ${response.body}');
    }
  }
}
