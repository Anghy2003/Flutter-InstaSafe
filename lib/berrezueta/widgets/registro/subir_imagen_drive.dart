import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<String?> subirImagenADrive(File imagen, String accessToken, String carpetaId) async {
  try {
    final bytes = await imagen.readAsBytes();
    final nombreArchivo = 'rostro_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final metadata = {
      'name': nombreArchivo,
      'mimeType': 'image/jpeg',
      'parents': [carpetaId],
    };

    final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromString(
        'metadata',
        jsonEncode(metadata),
        contentType: MediaType('application', 'json'),
      ))
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: nombreArchivo,
        contentType: MediaType('image', 'jpeg'),
      ));

    print('🟢 Subiendo imagen a Drive...');
    print('📎 Archivo: $nombreArchivo');
    print('📂 CarpetaID: $carpetaId');

    final response = await request.send();
    print('🔴 Código de respuesta: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final fileId = jsonDecode(body)['id'];

      // Hacer la imagen pública
      final permisoResponse = await http.post(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId/permissions'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': 'reader', 'type': 'anyone'}),
      );

      if (permisoResponse.statusCode == 200 || permisoResponse.statusCode == 204) {
        final urlDescarga = 'https://drive.google.com/uc?id=$fileId';
        print('✅ Imagen subida con éxito: $urlDescarga');
        return urlDescarga;
      } else {
        print('⚠ No se pudo compartir el archivo públicamente');
        return null;
      }
    } else {
      final error = await response.stream.bytesToString();
      print('❌ Error al subir imagen: $error');
      return null;
    }
  } catch (e) {
    print('❌ Excepción en subida: $e');
    return null;
  }
}