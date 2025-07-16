import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instasafe/berrezueta/widgets/registro/validaciones_registro.dart';

class EstiloInputRegistro extends StatelessWidget {
  final String etiqueta;
  final String textoPlaceholder;
  final IconData icono;
  final String tipoCampo;
  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;

  // Para campos tipo contraseña
  final bool esContrasena;
  final bool ocultarTexto;
  final VoidCallback? onToggleVisibilidad;

  final String? Function(String?)? validator;

  const EstiloInputRegistro({
    super.key,
    required this.etiqueta,
    required this.textoPlaceholder,
    required this.icono,
    required this.tipoCampo,
    this.controller,
    this.inputFormatters,
    this.esContrasena = false,
    this.ocultarTexto = true,
    this.onToggleVisibilidad,
    this.validator,
  });

  String? _validarCampo(String value) {
    switch (tipoCampo.toLowerCase()) {
      case 'cedula':
        return ValidacionesRegistro.validarCedula(value);
      case 'nombre':
        return ValidacionesRegistro.validarNombre(value);
      case 'apellido':
        return ValidacionesRegistro.validarApellido(value);
      case 'telefono':
        return ValidacionesRegistro.validarTelefono(value);
      case 'email':
        return ValidacionesRegistro.validarEmail(value);
      case 'password':
      case 'contraseña':
        return ValidacionesRegistro.validarPassword(value);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: esContrasena ? ocultarTexto : false,
        style: const TextStyle(color: Colors.white),
        validator: validator ?? (value) => _validarCampo(value ?? ''),
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: etiqueta,
          labelStyle: const TextStyle(color: Colors.white),
          hintText: textoPlaceholder,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icono, color: Colors.white),
          suffixIcon: esContrasena
              ? IconButton(
                  icon: Icon(
                    ocultarTexto ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                  ),
                  onPressed: onToggleVisibilidad,
                )
              : null,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        keyboardType: _definirTipoTeclado(),
      ),
    );
  }

  TextInputType _definirTipoTeclado() {
  switch (tipoCampo.toLowerCase()) {
    case 'cedula':
    case 'telefono':
      return TextInputType.number;
    case 'email':
      return TextInputType.emailAddress;
    case 'password':
    case 'contraseña':
      return TextInputType.visiblePassword;
    default:
      return TextInputType.text;
  }
}

}
