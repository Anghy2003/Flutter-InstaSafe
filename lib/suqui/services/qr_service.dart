import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrService {
  static const _secretKey = 'DaschAdbbMaii';

  static String generateEncryptedPayload(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = '$userId|$timestamp';

    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final signature = hmac.convert(utf8.encode(payload)).toString();

    final full = '$payload|$signature';
    return base64Url.encode(utf8.encode(full));
  }

  /// Desencripta y valida un payload QR
  static String? decryptAndValidate(String encrypted) {
    try {
      final decoded = utf8.decode(base64Url.decode(encrypted));
      final parts = decoded.split('|');
      if (parts.length != 3) return null;

      final userId = parts[0];
      final timestamp = int.tryParse(parts[1]) ?? 0;
      final signature = parts[2];

      // Validar firma
      final payload = '$userId|$timestamp';
      final hmac = Hmac(sha256, utf8.encode(_secretKey));
      final expectedSignature = hmac.convert(utf8.encode(payload)).toString();

      if (signature != expectedSignature) return null;

      // Validar tiempo (máximo 2 minutos)
      final now = DateTime.now().millisecondsSinceEpoch;
      if ((now - timestamp).abs() > 2 * 60 * 1000) return null;

      return userId;
    } catch (_) {
      return null;
    }
  }
}
