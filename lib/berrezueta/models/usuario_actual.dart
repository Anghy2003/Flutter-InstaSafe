import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:instasafe/suqui/services/qr_service.dart';

class UsuarioActual {
  // 🌐 Datos de autenticación
  static int? id;
  static String? accessToken;
  static String? carpetaDriveId;
  static String? fotoUrl;
  static String? correo;

  // 🧑‍💻 Atributos individuales extraídos del modelo de usuario
  static String? fotoGoogle; // Foto de Google
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
    fotoGoogle = null;
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

  // 1️⃣ Codifica el correo para la URL
  final encodedCorreo = Uri.encodeComponent(correoBuscado);
  final uri = Uri.parse(
    'https://spring-instasafe-441403171241.us-central1.run.app'
    '/api/usuarios/correo/$encodedCorreo'
  );

  print('🔍 Haciendo GET a: $uri');
  try {
    // 2️⃣ Lanza la petición y loguea resultado
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    print('⚙️ Código de GET: ${response.statusCode}');
    print('⚙️ Body de GET : ${response.body}');

    if (response.statusCode != 200) {
      // Aquí verás 404 o cualquier otro error
      return false;
    }

    // 3️⃣ Si es 200, parsea y asigna los campos
    final data = json.decode(response.body);
    id               = data['id'];
    correo           = data['correo'];
    cedula           = data['cedula'];
    nombre           = data['nombre'];
    apellido         = data['apellido'];
    
    genero           = data['genero'];
    idresponsable    = data['idresponsable'];
    fechanacimiento  = DateTime.tryParse(data['fechanacimiento'] ?? '');
    contrasena       = data['contrasena'];    // si tu endpoint la incluye
    idRol            = (data['id_rol'] is Map)
                       ? data['id_rol']['id']
                       : data['id_rol'];
    plantillaFacial  = data['plantillaFacial'];

    return true;
  } catch (e) {
    print('❌ Error al consultar usuario: $e');
    return false;
  }
}


//diego foto del google y el Qr
static Future<bool> iniciarSesion(String correo, String clave) async {
  // 1⃣ — Validar credenciales
  final loginUri = Uri.parse(
    'https://spring-instasafe-441403171241.us-central1.run.app/api/login'
  ).replace(queryParameters: {
    'correo': correo,
    'contrasena': clave,
  });
  print('🔍 [LOGIN] POST a: $loginUri');

  try {
    final loginResp = await http.post(loginUri);
    print('⚙️ [LOGIN] Código: ${loginResp.statusCode}');
    print('⚙️ [LOGIN] Body  : ${loginResp.body}');
    if (loginResp.statusCode != 200) {
      print('❌ Credenciales inválidas');
      return false;
    }

    // 2⃣ — Traer TODO el usuario
    final correoEnc = Uri.encodeComponent(correo);
    final getUri = Uri.parse(
      'https://spring-instasafe-441403171241.us-central1.run.app'
      '/api/usuarios/correo/$correoEnc'
    );
    print('🔍 [GET USER] GET a: $getUri');

    final getResp = await http.get(
      getUri,
      headers: {'Content-Type': 'application/json'},
    );
    print('⚙️ [GET USER] Código: ${getResp.statusCode}');
    print('⚙️ [GET USER] Body  : ${getResp.body}');
    if (getResp.statusCode != 200) {
      print('❌ No se encontró usuario por correo');
      return false;
    }

    // 3⃣ — Parseo y asignación de TODOS los campos en UsuarioActual
    final data = json.decode(getResp.body);
    id               = data['id'];
    correo           = data['correo'];
    cedula           = data['cedula'];
    nombre           = data['nombre'];
    apellido         = data['apellido'];
    // ← asignamos aquí la URL de "foto" al atributo fotoGoogle
    fotoGoogle       = data['fotoGoogle'] as String?;    
    genero           = data['genero'];
    idresponsable    = data['idresponsable'];
    fechanacimiento  = DateTime.tryParse(data['fechanacimiento'] ?? '');
    contrasena       = data['contrasena'];
    idRol            = (data['id_rol'] is Map)
                       ? data['id_rol']['id']
                       : data['id_rol'];
    plantillaFacial  = data['plantillaFacial'];

    print('✅ iniciarSesion completado: '
          'id=$id, nombre=$nombre $apellido, fotoGoogle=$fotoGoogle');
    return true;

  } catch (e) {
    print('❌ Error en iniciarSesion: $e');
    return false;
  }
}




static Future<String?> generarQrToken() async {
    final id = cedula;
    if (id == null || id.isEmpty) return null;
    return QrService.generateEncryptedPayload(id);
  }


}