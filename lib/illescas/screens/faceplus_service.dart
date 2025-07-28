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
      log('🔍 Iniciando verificación en Face++ con URL: $imageUrl');
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

      log('📨 Respuesta HTTP verificación: ${response.statusCode}');
      log('📄 Body verificación: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final confidence = result['confidence'];
          final userId = result['user_id'];

          log('📌 Resultado más cercano: user_id=$userId, confianza=$confidence');

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
          log('⚠️ No se encontraron coincidencias en el FaceSet');
        }
      } else {
        log('❌ Error HTTP al verificar rostro: ${response.body}');
      }
    } catch (e, stack) {
      log('❌ Excepción al verificar rostro: $e', stackTrace: stack);
    }
    return null;
  }

  /// 📝 Registra un rostro en el FaceSet usando una URL y un userId
  static Future<Map<String, dynamic>?> registrarFaceDesdeUrl(String imageUrl, String userId) async {
    try {
      log('📝 Iniciando registro de rostro con userId: $userId');
      log('🔁 Verificando si ya existe un rostro similar...');
      final yaRegistrado = await verificarFaceDesdeUrl(imageUrl);
      if (yaRegistrado != null) {
        final coincidenciaId = yaRegistrado['user_id'] ?? 'desconocido';
        log('🚫 Ya existe un rostro similar en FaceSet con userId: $coincidenciaId');
        return null;
      }

      log('📸 Enviando imagen para detección facial...');
      final detectResponse = await http.post(
        Uri.parse('https://api-us.faceplusplus.com/facepp/v3/detect'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'api_key': _apiKey,
          'api_secret': _apiSecret,
          'image_url': imageUrl,
        },
      ).timeout(_defaultTimeout);

      log('📨 Respuesta HTTP detección: ${detectResponse.statusCode}');
      log('📄 Body detección: ${detectResponse.body}');

      if (detectResponse.statusCode != 200) {
        log('❌ Error detectando rostro: ${detectResponse.body}');
        return null;
      }

      final detectData = jsonDecode(detectResponse.body);
      if (detectData['faces'] == null || detectData['faces'].isEmpty) {
        log('❌ No se detectó ningún rostro en la imagen');
        return null;
      }

      final faceToken = detectData['faces'][0]['face_token'];
      log('🆔 face_token detectado: $faceToken');

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

        log('📨 Respuesta HTTP addface: ${addResponse.statusCode}');
        log('📄 Body addface: ${addResponse.body}');

        if (addResponse.statusCode == 200) {
          log('✅ face_token agregado exitosamente al FaceSet');
          break;
        }

        if (addResponse.statusCode == 403 &&
            addResponse.body.contains('CONCURRENCY_LIMIT_EXCEEDED') &&
            intento < maxIntentos) {
          log('⏳ Concurrency limit excedido. Reintentando en 2 segundos...');
          await Future.delayed(delayEntreIntentos);
        } else {
          log('❌ Error al agregar face_token: ${addResponse.body}');
          return null;
        }
      }

      log('🔗 Asignando user_id al face_token...');
      final asignado = await asignarUserId(faceToken, userId);
      if (!asignado) {
        log('❌ Falló la asignación del user_id');
        return null;
      }

      log('🎉 Registro facial completado con éxito');
      return {
        'face_token': faceToken,
        'user_id': userId,
      };
    } catch (e, stack) {
      log('❌ Excepción en registrarFaceDesdeUrl: $e', stackTrace: stack);
      return null;
    }
  }

  /// 🔗 Asigna un `user_id` (cédula) a un `face_token`
  static Future<bool> asignarUserId(String faceToken, String userId) async {
    try {
      log('📌 Asignando user_id="$userId" al face_token="$faceToken"');
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

      log('📨 Respuesta HTTP setuserid: ${response.statusCode}');
      log('📄 Body setuserid: ${response.body}');

      if (response.statusCode == 200) {
        log('✅ user_id asignado correctamente');
        return true;
      } else {
        log('❌ Error al asignar user_id: ${response.body}');
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
      log('🧽 Solicitando eliminación de face_token="$faceToken" del FaceSet');
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

      log('📨 Respuesta HTTP removeface: ${response.statusCode}');
      log('📄 Body removeface: ${response.body}');

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
