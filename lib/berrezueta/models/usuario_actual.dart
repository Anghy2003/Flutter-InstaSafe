

import 'package:instasafe/models/usuario_model.dart';

class UsuarioActual {
  static Usuario? datos;          
  static String? accessToken;     
  static String? carpetaDriveId;  

  static void limpiar() {
    datos = null;
    accessToken = null;
    carpetaDriveId = null;
  }
}