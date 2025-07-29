import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:instasafe/suqui/services/qr_service.dart';

class UsuarioActual {
  static int? id;
  static String? accessToken;
  static String? carpetaDriveId;
  static String? fotoUrl;
  static String? correo;

  static String? fotoGoogle; 
  static String? cedula;
  static String? nombre;
  static String? apellido;
  static String? genero;
  static int? idresponsable;
  static DateTime? fechanacimiento;
  static String? contrasena;
  static int? idRol;
  static String? plantillaFacial;
  
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

  static Future<bool> cargarDesdeCorreo(String correoBuscado) async {
  if (correoBuscado.isEmpty) return false;

  final encodedCorreo = Uri.encodeComponent(correoBuscado);
  final uri = Uri.parse(
    'https://spring-instasafe-441403171241.us-central1.run.app'
    '/api/usuarios/correo/$encodedCorreo'
  );

  print('🔍 Haciendo GET a: $uri');
  try {
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    print('⚙️ Código de GET: ${response.statusCode}');
    print('⚙️ Body de GET : ${response.body}');

    if (response.statusCode != 200) {
      return false;
    }

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


static Future<bool> iniciarSesion(String correo, String clave) async {
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

    final data = json.decode(getResp.body);
    id               = data['id'];
    correo           = data['correo'];
    cedula           = data['cedula'];
    nombre           = data['nombre'];
    apellido         = data['apellido'];
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