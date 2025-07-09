import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:instasafe/illescas/screens/verificar.dart';
import 'package:instasafe/models/generadorplantilla.dart';
import 'package:instasafe/models/plantillafacial.dart';


Future<void> tomarFotoYVerificar(BuildContext context) async {
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se tomó ninguna foto.')),
      );
      return;
    }

    // 🧠 Generar plantilla facial desde imagen
    final generador = GeneradorPlantillaFacial();
    await generador.inicializarModelo();
    final base64 = await generador.generarDesdeImagen(File(pickedFile.path));

    if (base64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No se detectó rostro en la imagen.')),
      );
      return;
    }

    // 🌐 Enviar plantilla al backend para comparación
    final url = Uri.parse('http://TU_IP:PORT/api/verificacion/plantilla'); // Ajusta URL real

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'plantillaFacial': base64}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      // ✅ Redirigir con datos recibidos
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificacionResultadoScreen(datosUsuario: jsonData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error del servidor (${response.statusCode})')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error: $e')),
    );
  }
}
