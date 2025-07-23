// estilo_input_registro.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EstiloInputRegistro extends StatelessWidget {
  final String etiqueta;
  final String textoPlaceholder;
  final IconData icono;
  final String tipoCampo; // 'cedula', 'nombre', 'apellido', 'telefono', 'email', 'password', etc.
  final TextEditingController controller;

  // Opcionales:
  final FocusNode? focusNode;
  final String? errorText;
  final VoidCallback? onEditingComplete;

  final List<TextInputFormatter>? inputFormatters;
  final bool esContrasena;
  final bool ocultarTexto;
  final VoidCallback? onToggleVisibilidad;

  const EstiloInputRegistro({
    Key? key,
    required this.etiqueta,
    required this.textoPlaceholder,
    required this.icono,
    required this.tipoCampo,
    required this.controller,
    this.focusNode,
    this.errorText,
    this.onEditingComplete,
    this.inputFormatters,
    this.esContrasena = false,
    this.ocultarTexto = false,
    this.onToggleVisibilidad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Selecciona el teclado según el tipo de campo:
    TextInputType keyboardType;
    List<TextInputFormatter>? _inputFormatters = inputFormatters;

    switch (tipoCampo) {
      case 'cedula':
        keyboardType = TextInputType.number; // Solo números
        _inputFormatters ??= [
          LengthLimitingTextInputFormatter(10),
          FilteringTextInputFormatter.digitsOnly
        ];
        break;
      case 'telefono':
        keyboardType = TextInputType.phone; // Permite números y '+'
        break;
      case 'email':
        keyboardType = TextInputType.emailAddress;
        break;
      case 'nombre':
      case 'apellido':
        keyboardType = TextInputType.text; // Letras
        break;
      case 'password':
        keyboardType = TextInputType.visiblePassword;
        break;
      default:
        keyboardType = TextInputType.text;
    }

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: _inputFormatters,
      obscureText: esContrasena ? ocultarTexto : false,
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: textoPlaceholder,
        prefixIcon: Icon(icono),
        errorText: errorText,
        suffixIcon: esContrasena
            ? IconButton(
                icon: Icon(
                  ocultarTexto ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onToggleVisibilidad,
              )
            : null,
        border: const UnderlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
      onEditingComplete: onEditingComplete,
      validator: (_) => null, // La validación se hace externamente
    );
  }
}
