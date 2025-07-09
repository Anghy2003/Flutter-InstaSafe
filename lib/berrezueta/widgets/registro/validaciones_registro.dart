// validaciones_registro.dart

class ValidacionesRegistro {
  static String? validarCedula(String value) {
    final cedula = value.trim();
    if (cedula.isEmpty) return 'La cédula es obligatoria';
    if (!RegExp(r'^\d{10}$').hasMatch(cedula)) {
      return 'La cédula debe tener 10 dígitos numéricos';
    }

    // Validación para cédula ecuatoriana
    final provincia = int.parse(cedula.substring(0, 2));
    final tercerDigito = int.parse(cedula.substring(2, 3));
    if (provincia < 1 || provincia > 24) return 'Provincia inválida en la cédula';
    if (tercerDigito > 6) return 'Formato incorrecto para cédula ecuatoriana';

    // Algoritmo de validación (módulo 10)
    final coeficientes = [2, 1 , 2, 1, 2, 1, 2, 1, 2];
    int suma = 0;
    for (int i = 0; i < coeficientes.length; i++) {
      int valor = coeficientes[i] * int.parse(cedula[i]);
      suma += valor > 9 ? valor - 9 : valor;
    }
    int digitoVerificador = suma % 10 == 0 ? 0 : 10 - (suma % 10);
    if (digitoVerificador != int.parse(cedula[9])) return 'Cédula inválida';

    return null;
  }

  static String? validarNombre(String value) {
    final nombre = value.trim();
    if (nombre.isEmpty) return 'El nombre es obligatorio';
    if (!RegExp(r"^[a-zA-ZÁÉÍÓÚÑáéíóúñ\s]+$").hasMatch(nombre)) {
      return 'El nombre solo debe contener letras';
    }
    return null;
  }

  static String? validarApellido(String value) {
  final apellido = value.trim();
  if (apellido.isEmpty) return 'El apellido es obligatorio';
  if (!RegExp(r"^[a-zA-ZÁÉÍÓÚÑáéíóúñ\s]+$").hasMatch(apellido)) {
    return 'El apellido solo debe contener letras';
  }
  return null;
}


  static String? validarTelefono(String value) {
    final telefono = value.trim();
    if (telefono.isEmpty) return 'El teléfono es obligatorio';
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(telefono)) {
      return 'Teléfono inválido';
    }
    return null;
  }

  static String? validarEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'El email es obligatorio';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Email inválido';
    }
    return null;
  }

  static String? validarPassword(String value) {
    if (value.trim().isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}