import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:instasafe/illescas/widgets/AwsRekognitionConfig.dart';
import 'package:intl/intl.dart';

class AwsRekognitionService {
  static const double umbralConfianza = 75.0;

  static Future<Map<String, dynamic>?> verificarFaceDesdeUrl(String imageUrl) async {
    print('🔍 Verificando rostro en AWS Rekognition');
    final resultado = await buscarPorUrl(imageUrl);

    if (resultado != null) {
      final double confianza = resultado['confidence'] ?? 0;
      final usuarioId = resultado['externalImageId'] ?? 'desconocido';

      print('👤 Coincidencia con ID: $usuarioId (confianza: $confianza)');

      if (confianza >= umbralConfianza) {
        print('✅ Coincidencia válida (≥ $umbralConfianza)');
        return resultado;
      } else {
        print('❌ Confianza insuficiente (< $umbralConfianza)');
        return null;
      }
    }

    print('😕 No se encontró coincidencia en la colección');
    return null;
  }

  static Future<Map<String, dynamic>?> buscarPorUrl(String imageUrl) async {
    final String target = 'RekognitionService.SearchFacesByImage';

    final payload = jsonEncode({
      'CollectionId': AwsRekognitionConfig.collectionId,
      'Image': {'Url': imageUrl},
      'FaceMatchThreshold': umbralConfianza,
      'MaxFaces': 1,
    });

    final response = await _enviarPeticionAWS(payload, target);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['FaceMatches'] != null && data['FaceMatches'].isNotEmpty) {
        final face = data['FaceMatches'][0]['Face'];
        return {
          'faceId': face['FaceId'],
          'externalImageId': face['ExternalImageId'],
          'confidence': data['FaceMatches'][0]['Similarity'],
        };
      }
    } else {
      print('❌ Error buscando rostro: ${response.body}');
    }

    return null;
  }

  static Future<bool> registrarFaceDesdeUrl(String imageUrl, String userId) async {
    print('📝 Registrando rostro en AWS Rekognition');
    final String target = 'RekognitionService.IndexFaces';

    final payload = jsonEncode({
      'CollectionId': AwsRekognitionConfig.collectionId,
      'Image': {'Url': imageUrl},
      'ExternalImageId': userId,
      'DetectionAttributes': [],
    });

    final response = await _enviarPeticionAWS(payload, target);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['FaceRecords'] != null && data['FaceRecords'].isNotEmpty) {
        print('✅ Rostro indexado correctamente');
        return true;
      } else {
        print('❌ No se detectó rostro válido en la imagen');
      }
    } else {
      print('❌ Error registrando rostro: ${response.body}');
    }

    return false;
  }

 static Future<http.Response> _enviarPeticionAWS(String payload, String target) async {
  final date = DateTime.now().toUtc();
  final service = 'rekognition';
  final method = 'POST';
  final region = AwsRekognitionConfig.region;
  final host = 'rekognition.$region.amazonaws.com';
  final endpoint = 'https://$host/';
  final contentType = 'application/x-amz-json-1.1';
  final amzDate = DateFormat('yyyyMMdd\'T\'HHmmss\'Z\'').format(date);
  final dateStamp = DateFormat('yyyyMMdd').format(date);

  // Canonical headers
  final canonicalHeaders = 'content-type:$contentType\nhost:$host\nx-amz-date:$amzDate\n';
  final signedHeaders = 'content-type;host;x-amz-date';

  // Hash del payload
  final hashedPayload = sha256.convert(utf8.encode(payload)).toString();

  // Canonical request
  final canonicalRequest = [
    method,
    '/',
    '',
    canonicalHeaders,
    signedHeaders,
    hashedPayload
  ].join('\n');

  // String to sign
  final algorithm = 'AWS4-HMAC-SHA256';
  final credentialScope = '$dateStamp/$region/$service/aws4_request';
  final stringToSign = [
    algorithm,
    amzDate,
    credentialScope,
    sha256.convert(utf8.encode(canonicalRequest)).toString()
  ].join('\n');

  // Generar firma
  List<int> _sign(List<int> key, String message) =>
      Hmac(sha256, key).convert(utf8.encode(message)).bytes;

  final kSecret = utf8.encode('AWS4${AwsRekognitionConfig.secretKey}');
  final kDate = _sign(kSecret, dateStamp);
  final kRegion = _sign(kDate, region);
  final kService = _sign(kRegion, service);
  final kSigning = _sign(kService, 'aws4_request');

  final signature =
      Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();

  final authorizationHeader =
      '$algorithm Credential=${AwsRekognitionConfig.accessKey}/$credentialScope, '
      'SignedHeaders=$signedHeaders, Signature=$signature';

  final headers = {
    'Content-Type': contentType,
    'Host': host, // ✅ importante para que AWS valide bien la firma
    'X-Amz-Date': amzDate,
    'X-Amz-Target': target,
    'Authorization': authorizationHeader,
  };

  print('📤 Enviando petición firmada a AWS Rekognition...');
  return await http.post(Uri.parse(endpoint), headers: headers, body: payload);
}

}
