import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:instasafe/models/usuario_model.dart';


Future<List<Usuario>> cargarUsuariosDesdeBackend() async {
  final url = Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app//api/usuarios'); // ✅ tu IP real
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data.map((json) => Usuario.fromJson(json)).toList();
  } else {
    throw Exception('Error al cargar usuarios: ${response.statusCode}');
  }
}
