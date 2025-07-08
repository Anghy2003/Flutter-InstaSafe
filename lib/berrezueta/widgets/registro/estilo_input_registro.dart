import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instasafe/berrezueta/widgets/registro/validaciones_registro.dart';

class EstiloInputRegistro extends StatelessWidget {
  final String etiqueta;
  final String textoPlaceholder;
  final IconData icono;
  final bool esPassword;
  final String tipoCampo;
  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;

  const EstiloInputRegistro({
    super.key,
    required this.etiqueta,
    required this.textoPlaceholder,
    required this.icono,
    required this.tipoCampo,
    this.controller,
    this.inputFormatters,
    this.esPassword = false,
  });

  String? _validarCampo(String value) {
    switch (tipoCampo.toLowerCase()) {
      case 'cedula':
        return ValidacionesRegistro.validarCedula(value);
      case 'nombre':
        return ValidacionesRegistro.validarNombre(value);
      case 'telefono':
        return ValidacionesRegistro.validarTelefono(value);
      case 'email':
        return ValidacionesRegistro.validarEmail(value);
      case 'contraseña':
        return ValidacionesRegistro.validarPassword(value);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(color: Colors.white70)),
          Row(
            children: [
              Icon(icono, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  obscureText: esPassword,
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => _validarCampo(value ?? ''),
                  inputFormatters: inputFormatters,
                  decoration: InputDecoration(
                    hintText: textoPlaceholder,
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (esPassword)
                const Icon(Icons.visibility, color: Colors.white),
            ],
          ),
          const Divider(color: Colors.white38, thickness: 1),
        ],
      ),
    );
  }
}