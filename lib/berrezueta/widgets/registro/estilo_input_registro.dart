// estilo_input_registro.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EstiloInputRegistro extends StatelessWidget {
  final String etiqueta;
  final String textoPlaceholder;
  final IconData icono;
  final String tipoCampo; // 'cedula', 'nombre', 'apellido', 'telefono', 'email', 'password', etc.
  final TextEditingController controller;

  /// Estos son los nuevos parámetros que agregamos:
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

    // nuevos
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
    TextInputType keyboardType;
    switch (tipoCampo) {
      case 'email':
        keyboardType = TextInputType.emailAddress;
        break;
      case 'telefono':
        keyboardType = TextInputType.phone;
        break;
      case 'cedula':
      case 'nombre':
      case 'apellido':
      default:
        keyboardType = TextInputType.text;
    }

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
      validator: (_) => null, // dejamos la validación por separado
    );
  }
}
