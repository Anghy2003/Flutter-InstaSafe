import 'package:flutter/services.dart';

class TelefonoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Si empieza con +593
    if (text.startsWith('+593')) {
      if (text.length > 13) {
        return oldValue;
      }
    }
    // Si empieza con 09
    else if (text.startsWith('09')) {
      if (text.length > 10) {
        return oldValue;
      }
    }
    else if (text.length > 13) {
      return oldValue;
    }

    // Solo permite dígitos y +
    if (!RegExp(r'^[0-9+]*$').hasMatch(text)) {
      return oldValue;
    }

    return newValue;
  }
}
