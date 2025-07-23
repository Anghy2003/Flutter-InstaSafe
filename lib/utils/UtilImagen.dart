import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/services/isolate_helpers.dart';
import 'package:path_provider/path_provider.dart';



class UtilImagen {
  /// 🔧 Redimensiona y comprime la imagen en un Isolate
  static Future<File> reducirImagen(File original) async {
  final tempDir = await getTemporaryDirectory(); // <<--- AQUÍ sí puedes
  final receivePort = ReceivePort();
  await Isolate.spawn(
    reducirImagenIsolate,
    ReducirImagenArgs(original.path, tempDir.path, receivePort.sendPort),
  );
  final result = await receivePort.first as Map;
  if (result.containsKey('filePath')) {
    return File(result['filePath']);
  } else {
    throw Exception(result['error'] ?? 'Error desconocido en reducción');
  }
}


  /// ☁️ Sube imagen a Cloudinary para uso en Face++
  static Future<String?> subirACloudinary(File imagen) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/dizj9rwfx/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'rostros_usuarios'
        ..files.add(await http.MultipartFile.fromPath('file', imagen.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final jsonData = json.decode(body);
        final url = jsonData['secure_url'];
        print('✅ Imagen subida a Cloudinary: $url');
        return url;
      } else {
        print('❌ Error Cloudinary (${response.statusCode})');
        return null;
      }
    } catch (e) {
      print('❌ Excepción subiendo a Cloudinary: $e');
      return null;
    }
  }

  /// 🔁 Reducción + subida a Cloudinary
  static Future<String?> prepararImagenParaRegistro(File imagenOriginal) async {
    try {
      final imagenReducida = await reducirImagen(imagenOriginal);
      final urlCloudinary = await subirACloudinary(imagenReducida);
      return urlCloudinary;
    } catch (e) {
      print('❌ Error en prepararImagenParaRegistro: $e');
      return null;
    }
  }
}
