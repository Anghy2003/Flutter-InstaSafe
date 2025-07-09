import 'dart:convert';

class PlantillaFacial {
  final List<double> embedding; // 🌐 Vector de características faciales

  PlantillaFacial(this.embedding);

  /// Convierte a formato JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'embedding': embedding,
    };
  }

  /// Convierte a una string base64 para almacenar en BD como texto
  String toBase64() {
    final bytes = utf8.encode(jsonEncode(toJson()));
    return base64Encode(bytes);
  }

  /// Construir desde una base64 guardada en la base de datos
  factory PlantillaFacial.fromBase64(String base64String) {
    final jsonString = utf8.decode(base64Decode(base64String));
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final List<dynamic> rawList = json['embedding'];
    final List<double> vector = rawList.map((e) => (e as num).toDouble()).toList();
    return PlantillaFacial(vector);
  }
}
