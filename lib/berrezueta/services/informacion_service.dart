import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/models/evento_models.dart';

Future<Evento?> obtenerEventoPorId(int id) async {
  try {
    final response = await http.get(
      Uri.parse('https://tuservidor.com/api/eventos/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Evento.fromJson(data);
    }
  } catch (e) {
    print('❌ Error al obtener evento: $e');
  }
  return null;
}