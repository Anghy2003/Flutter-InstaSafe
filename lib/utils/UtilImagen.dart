import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class UtilImagen {
  /// 🔧 Redimensiona y comprime la imagen para evitar errores por tamaño
  static Future<File> reducirImagen(File original) async {
    final bytes = await original.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('No se pudo leer la imagen');

    final resized = img.copyResize(image, width: 400); // Reducción a 400 px
    final jpg = img.encodeJpg(resized, quality: 30);   // Alta compresión

    final dir = await getTemporaryDirectory();
    final nuevoArchivo = File('${dir.path}/reducida_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await nuevoArchivo.writeAsBytes(jpg);
    return nuevoArchivo;
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
