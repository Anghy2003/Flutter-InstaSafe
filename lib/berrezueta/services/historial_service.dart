import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/models/evento_models.dart';

class HistorialService {
  static const String _baseUrl = 'https://spring-instasafe-441403171241.us-central1.run.app/api/eventos';

  /// Obtiene las fechas disponibles para el historial
  static Future<List<String>> fetchFechasDisponibles() async {
    try {
      final url = Uri.parse('$_baseUrl/fechas-disponibles');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final fechas = List<String>.from(json.decode(response.body));
        return ['Todas', ...fechas];
      } else {
        throw Exception('Error al obtener fechas disponibles');
      }
    } catch (e) {
      print('Error en fetchFechasDisponibles: $e');
      rethrow;
    }
  }

  /// Obtiene los eventos/accesos según la fecha seleccionada
  static Future<List<Evento>> fetchAccesos(String fecha) async {
    try {
      Uri url;
      if (fecha == 'Todas') {
        url = Uri.parse(_baseUrl);
      } else {
        url = Uri.parse('$_baseUrl/filtrar?fecha=$fecha');
      }

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<Evento> eventos = jsonList.map((e) => Evento.fromJson(e)).toList();

        // Debug log
        for (var evento in eventos) {
          print('Evento ID: ${evento.id} → Guardia: ${evento.guardia.id}, Usuario: ${evento.usuario.id}');
        }

        return eventos;
      } else {
        throw Exception('Error al obtener accesos');
      }
    } catch (e) {
      print('Error en fetchAccesos: $e');
      rethrow;
    }
  }
}