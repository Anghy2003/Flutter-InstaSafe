import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/widgets/registro/subir_imagen_drive.dart'; // 👈 ajusta según tu ruta

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
  required String plantillaFacialBase64,
  required String plantillaFacial,
}) async {
  try {
    final fotoUrl = await subirImagenADrive(imagen, accessToken, carpetaDriveId);

    if (fotoUrl == null) {
      return '❌ Error al subir imagen a Drive';
    }

    print('📤 Enviando datos de usuario con foto: $fotoUrl');

    final uri = Uri.parse('http://192.168.56.31:8090/api/usuarios');
    final response = await http.post(
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
        'plantillaFacial': plantillaFacialBase64, // 👈 asegúrate que el nombre coincide con tu backend
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Usuario registrado correctamente');
      return 'ok';
    } else {
      print('❌ Error al registrar usuario: ${response.body}');
      return 'Servidor respondió con error: ${response.body}';
    }
  } catch (e) {
    print('❌ Excepción al registrar usuario: $e');
    return 'Excepción de conexión: $e';
  }
}
