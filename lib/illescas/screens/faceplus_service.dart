import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class FacePlusService {
  static const _apiKey = '9q_gaekHAXZHLr8UtwI1_mDQwzemtkhX';
  static const _apiSecret = 'vOMfoLRFR4jTwVIjeB4hP9_DYbucPblH';
  static const _outerId = 'istasafe_users';
  static const Duration _defaultTimeout = Duration(seconds: 15);

  /// 🔍 Verifica si el rostro ya está en el FaceSet (NO registra)
  static Future<Map<String, dynamic>?> verificarFaceDesdeUrl(String imageUrl) async {
    try {
      log('🔍 Verificando rostro en Face++');
      final uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/search');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'api_key': _apiKey,
          'api_secret': _apiSecret,
          'image_url': imageUrl,
          'outer_id': _outerId,
        },
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final confidence = result['confidence'];
          final userId = result['user_id'];

          if (confidence >= 75.0) {
            log('✅ Coincidencia válida (confianza: $confidence)');
            return {
              'face_token': result['face_token'],
              'confidence': confidence,
              'user_id': userId,
            };
          } else {
            log('❌ Confianza insuficiente ($confidence)');
          }
        } else {
          log('⚠️ No se encontraron coincidencias');
        }
      } else {
        log('❌ Error HTTP al verificar: ${response.body}');
      }
    } catch (e, stack) {
      log('❌ Excepción en verificación: $e', stackTrace: stack);
    }
    return null;
  }

  /// 📝 Registra un rostro en el FaceSet usando una URL y un userId
  static Future<bool> registrarFaceDesdeUrl(String imageUrl, String userId) async {
    try {
      log('📝 Iniciando registro de rostro para: $userId');
      // 1. Verificar si ya existe con algún usuario
      final yaRegistrado = await verificarFaceDesdeUrl(imageUrl);
      if (yaRegistrado != null) {
        final coincidenciaId = yaRegistrado['user_id'] ?? 'otro usuario';
        log('🚫 El rostro se parece al de otra persona ya registrada: $coincidenciaId');
        return false;
      }

      // 2. Detección del rostro
      log('📸 Enviando imagen a Face++ para detección...');
      final detectResponse = await http.post(
        Uri.parse('https://api-us.faceplusplus.com/facepp/v3/detect'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'api_key': _apiKey,
          'api_secret': _apiSecret,
          'image_url': imageUrl,
        },
      ).timeout(_defaultTimeout);

      log('📬 Respuesta de detect: ${detectResponse.statusCode}');
      if (detectResponse.statusCode != 200) {
        log('❌ Error detectando rostro: ${detectResponse.body}');
        return false;
      }

      final detectData = jsonDecode(detectResponse.body);
      if (detectData['faces'] == null || detectData['faces'].isEmpty) {
        log('❌ No se detectó ningún rostro en la imagen');
        return false;
      }
      final faceToken = detectData['faces'][0]['face_token'];
      log('🆔 face_token detectado: $faceToken');

      // 3. Intentar agregar al FaceSet (con reintentos eficientes)
      const maxIntentos = 4;
      const delayEntreIntentos = Duration(seconds: 2);
      int intento = 0;
      http.Response addResponse;
      final addUri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/faceset/addface');
      final addBody = {
        'api_key': _apiKey,
        'api_secret': _apiSecret,
        'outer_id': _outerId,
        'face_tokens': faceToken,
      };

      while (true) {
        intento++;
        log('🔁 Intento $intento para agregar face_token al FaceSet...');
        addResponse = await http.post(addUri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: addBody).timeout(_defaultTimeout);

        if (addResponse.statusCode == 200) break;

        if (addResponse.statusCode == 403 &&
            addResponse.body.contains('CONCURRENCY_LIMIT_EXCEEDED') &&
            intento < maxIntentos) {
          log('⏳ Concurrency limit excedido. Esperando 2 segundos antes de reintentar...');
          await Future.delayed(delayEntreIntentos);
        } else {
          log('❌ Error al agregar a FaceSet: ${addResponse.body}');
          return false;
        }
      }

      // 4. Asignar user_id
      log('🔗 Asignando user_id al rostro...');
      return await asignarUserId(faceToken, userId);
    } catch (e, stack) {
      log('❌ Excepción en registrarFaceDesdeUrl: $e', stackTrace: stack);
      return false;
    }
  }

  /// 🔗 Asigna un `user_id` (cédula) a un `face_token`
  static Future<bool> asignarUserId(String faceToken, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('https://api-us.faceplusplus.com/facepp/v3/face/setuserid'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'api_key': _apiKey,
          'api_secret': _apiSecret,
          'face_token': faceToken,
          'user_id': userId,
        },
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        log('✅ user_id asignado correctamente');
        return true;
      } else {
        log('❌ Error asignando user_id: ${response.body}');
        return false;
      }
    } catch (e, stack) {
      log('❌ Excepción en asignarUserId: $e', stackTrace: stack);
      return false;
    }
  }

  /// 🧽 Elimina un face_token del FaceSet
  static Future<bool> eliminarFaceToken(String faceToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://api-us.faceplusplus.com/facepp/v3/faceset/removeface'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'api_key': _apiKey,
          'api_secret': _apiSecret,
          'outer_id': _outerId,
          'face_tokens': faceToken,
        },
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        log('🗑️ face_token eliminado correctamente');
        return true;
      } else {
        log('❌ Error al eliminar token: ${response.body}');
        return false;
      }
    } catch (e, stack) {
      log('❌ Excepción en eliminarFaceToken: $e', stackTrace: stack);
      return false;
    }
  }
}
