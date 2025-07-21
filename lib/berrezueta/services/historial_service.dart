import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/models/evento_models.dart';

class HistorialService {
  static const String _baseUrl = 'https://spring-instasafe-441403171241.us-central1.run.app/api/eventos';

  static Future<List<String>> fetchFechasDisponibles() async {
    try {
      final uri = Uri.parse('$_baseUrl/fechas-disponibles');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        
        final List<String> fechas = List<String>.from(json.decode(response.body));
        // Orden descendente: recientes primero
        fechas.sort((a, b) => b.compareTo(a));
        
        return ['Todas', ...fechas];
      } else {
        throw Exception('Error ${response.statusCode} al obtener fechas disponibles');
      }
    } catch (e) {
      print('Error en fetchFechasDisponibles: $e');
      rethrow;
    }
  }


  static Future<List<Evento>> fetchAccesos(String fecha) async {
    try {
      final Uri uri = fecha == 'Todas'
          ? Uri.parse(_baseUrl)
          : Uri.parse('$_baseUrl/filtrar?fecha=$fecha');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((e) => Evento.fromJson(e)).toList();
      } else {
        throw Exception('Error ${response.statusCode} al obtener accesos');
      }
    } catch (e) {
      print('Error en fetchAccesos: $e');
      rethrow;
    }
  }
}
