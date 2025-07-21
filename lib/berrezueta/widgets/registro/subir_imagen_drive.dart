import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<String?> subirImagenADrive(
  File imagen,
  String carpetaId,
) async {
  const timeout = Duration(seconds: 20);
  final nombreArchivo = 'rostro_${DateTime.now().millisecondsSinceEpoch}.jpg';

  // Obtiene credenciales de GoogleSignIn
  final googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/drive.file'],
  );
  final cuenta = googleSignIn.currentUser ?? await googleSignIn.signInSilently();
  if (cuenta == null) {
    throw Exception('No hay sesion de Google activa');
  }
  final authHeaders = await cuenta.authHeaders;
  final authHeader = authHeaders['Authorization'];
  if (authHeader == null) {
    throw Exception('No se pudo obtener el header de autorizacion');
  }

  // Prepara metadata
  final metadata = {
    'name': nombreArchivo,
    'mimeType': 'image/jpeg',
    'parents': [carpetaId],
  };

  // Construye la peticion multipart
  final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = authHeader;

  request.files.add(http.MultipartFile.fromString(
    'metadata',
    jsonEncode(metadata),
    contentType: MediaType('application', 'json'),
  ));

  request.files.add(await http.MultipartFile.fromPath(
    'file',
    imagen.path,
    filename: nombreArchivo,
    contentType: MediaType('image', 'jpeg'),
  ));

  // Envía la peticion
  final streamedResponse = await request.send().timeout(timeout);
  if (streamedResponse.statusCode != 200) {
    final error = await streamedResponse.stream.bytesToString();
    print('Error al subir imagen a Drive: $error');
    return null;
  }

  // Lee la respuesta
  final body = await streamedResponse.stream.bytesToString();
  final fileId = jsonDecode(body)['id'];

  // Asigna permiso de lectura publica
  final permUri = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId/permissions');
  final permResponse = await http
      .post(
        permUri,
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': 'reader', 'type': 'anyone'}),
      )
      .timeout(timeout);

  if (permResponse.statusCode != 200 && permResponse.statusCode != 204) {
    print('No se pudo compartir el archivo publicamente: ${permResponse.body}');
    return null;
  }

  // Retorna la URL publica
  return 'https://drive.google.com/uc?id=$fileId';
}
