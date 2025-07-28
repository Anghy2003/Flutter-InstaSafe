import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lugar.dart';

class LugarService {
  final String _url = 'https://spring-instasafe-441403171241.us-central1.run.app/api/lugares';

  Future<List<Lugar>> obtenerLugares() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Lugar.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener lugares');
    }
  }
}
