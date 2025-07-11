import 'package:http/http.dart' as http;
import 'dart:convert';

class UsuarioActual {
  // 🌐 Datos de autenticación
  static String? accessToken;
  static String? carpetaDriveId;
  static String? fotoUrl;
  static String? correo;

  // 🧑‍💻 Atributos individuales extraídos del modelo de usuario
  static String? cedula;
  static String? nombre;
  static String? apellido;
  static String? genero;
  static int? idresponsable;
  static DateTime? fechanacimiento;
  static String? contrasena;
  static int? idRol;
  static String? plantillaFacial;

  // 🧹 Limpia todos los datos del usuario actual
  static void limpiar() {
    accessToken = null;
    carpetaDriveId = null;
    fotoUrl = null;
    correo = null;
    cedula = null;
    nombre = null;
    apellido = null;
    genero = null;
    idresponsable = null;
    fechanacimiento = null;
    contrasena = null;
    idRol = null;
    plantillaFacial = null;
  }

  // 🔎 Consulta el usuario en Spring por correo y llena todos los campos estáticos
  static Future<bool> cargarDesdeCorreo(String correoBuscado) async {
    if (correoBuscado.isEmpty) return false;

    try {
      final response = await http.get(
        Uri.parse(
          'https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/correo/$correoBuscado',
          //todo Verificar si se manda a buscar en la base spring con el metodo que hiciste, Dieguito tiene que subir a la baseishon
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 🎯 Asignación de atributos individuales
        correo = data['correo'];
        cedula = data['cedula'];
        nombre = data['nombre'];
        apellido = data['apellido'];
        genero = data['genero'];
        idresponsable = data['idresponsable'];
        fechanacimiento = DateTime.tryParse(data['fechanacimiento'] ?? '');
        contrasena = data['contrasena'];
        idRol = data['idRol'];
        plantillaFacial = data['plantillaFacial'];

        return true;
      } else {
        print('⚠ Usuario no encontrado. Código: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error al consultar usuario: $e');
      return false;
    }
  }
}