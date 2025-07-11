import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:instasafe/models/plantillafacial.dart';
import 'package:instasafe/illescas/screens/usuarioLigero.dart';
import 'package:instasafe/illescas/screens/comparadorfacial_ligero.dart';
import 'package:instasafe/berrezueta/widgets/registro/subir_imagen_drive.dart'; // Ajusta según tu estructura

Future<String> enviarDatosRegistroUsuario({
  required String cedula,
  required String nombre,
  required String apellido,
  required String correo,
  required String genero,
  required int idResponsable,
  required DateTime fechaNacimiento,
  required String contrasena,
  required int idRol,
  required File imagen,
  required String accessToken,
  required String carpetaDriveId,
  required String plantillaFacialBase64, required String plantillaFacial,
}) async {
  try {
    // Primero verifica si el rostro ya existe
    final plantillaNueva = PlantillaFacial.fromBase64(plantillaFacialBase64);

    final response = await http.get(
      Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas'),
    );

    if (response.statusCode != 200) {
      return '❌ Error al obtener plantillas existentes: ${response.statusCode}';
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final usuarios = jsonList.map((e) => UsuarioLigero.fromJson(e)).toList();

    final resultado = ComparadorFacialLigero.comparar(plantillaNueva, usuarios);

    if (resultado != null) {
      final coincidencia = resultado['usuario'] as UsuarioLigero;
      return '❌ Este rostro ya fue registrado con la cédula: ${coincidencia.cedula}';
    }

    // Si no hay coincidencia, subir imagen a Drive
    final fotoUrl = await subirImagenADrive(imagen, accessToken, carpetaDriveId);
    if (fotoUrl == null) {
      return '❌ Error al subir imagen a Drive';
    }

    print('📤 Enviando datos de usuario con foto: $fotoUrl');

    // Registrar el usuario en backend
    final uri = Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios');
    final registroResponse = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'genero': genero,
        'idresponsable': idResponsable.toString(),
        'fechanacimiento': fechaNacimiento.toIso8601String(),
        'contrasena': contrasena,
        'id_rol': idRol.toString(),
        'foto': fotoUrl,
        'plantillaFacial': plantillaFacialBase64,
      },
    );

    if (registroResponse.statusCode == 200 || registroResponse.statusCode == 201) {
      print('✅ Usuario registrado correctamente');
      return 'ok';
    } else {
      print('❌ Error al registrar usuario: ${registroResponse.body}');
      return 'Servidor respondió con error: ${registroResponse.body}';
    }
  } catch (e) {
    print('❌ Excepción al registrar usuario: $e');
    return 'Excepción de conexión: $e';
  }
}
