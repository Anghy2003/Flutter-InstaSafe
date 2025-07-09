import 'dart:io';
import 'package:flutter/material.dart';
import 'package:instasafe/berrezueta/widgets/registro/validaciones_registro.dart';

bool validarFormularioCompleto({
  required TextEditingController cedulaController,
  required TextEditingController nombreController,
  required TextEditingController apellidoController,
  required TextEditingController telefonoController,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required File? imagenSeleccionada,
  required DateTime? fechaNacimiento,
  required String? generoSeleccionado,
  required int? rolSeleccionado,
}) {
  final inputsLlenos = cedulaController.text.isNotEmpty &&
      nombreController.text.isNotEmpty &&
      apellidoController.text.isNotEmpty &&
      telefonoController.text.isNotEmpty &&
      emailController.text.isNotEmpty &&
      passwordController.text.isNotEmpty &&
      imagenSeleccionada != null &&
      fechaNacimiento != null &&
      generoSeleccionado != null &&
      rolSeleccionado != null;

  final camposValidos =
      ValidacionesRegistro.validarCedula(cedulaController.text) == null &&
      ValidacionesRegistro.validarNombre(nombreController.text) == null &&
      ValidacionesRegistro.validarNombre(apellidoController.text) == null &&
      ValidacionesRegistro.validarTelefono(telefonoController.text) == null &&
      ValidacionesRegistro.validarEmail(emailController.text) == null &&
      ValidacionesRegistro.validarPassword(passwordController.text) == null;

  return inputsLlenos && camposValidos;
}
