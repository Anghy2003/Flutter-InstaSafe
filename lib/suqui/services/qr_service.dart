import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrService {
  // **IMPORTANTE**: usa una clave secreta fuerte y mantenla fuera de Git
  static const _secretKey = 'DaschAdbbMaii';

  /// Genera un payload cifrado + firmado
  static String generateEncryptedPayload(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = '$userId|$timestamp';

    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final signature = hmac.convert(utf8.encode(payload)).toString();

    final full = '$payload|$signature';
    return base64Url.encode(utf8.encode(full));
  }

  /// Para leer (dentro de tu app), harías lo inverso:
  /// 1) base64Url.decode  2) split('|') 3) validar HMAC y timestamp
}
