import 'package:instasafe/berrezueta/models/evento_models.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';

class HistorialFiltro {
  /// Filtra los eventos según el rol del usuario actual
  static List<Evento> filterEventosByRole(List<Evento> eventos) {
    final rol = UsuarioActual.idRol;
    final usuarioId = UsuarioActual.id;

    if (rol == 1 || rol == 5) {
      // Admin y Seguridad - pueden ver todos los eventos
      return eventos;
    } else if (rol == 2 && usuarioId != null) {
      // Guardia - solo ve eventos donde él es el guardia
      return eventos.where((e) => e.guardia.id == usuarioId).toList();
    } else if ((rol == 3 || rol == 6) && usuarioId != null) {
      // Estudiante o Docente - solo ve sus propios eventos
      return eventos.where((e) => e.usuario.id == usuarioId).toList();
    } else {
      // Rol no reconocido o usuario sin ID
      return [];
    }
  }

  /// Obtiene la descripción del rol actual (para debugging o UI)
  static String getRoleDescription() {
    final rol = UsuarioActual.idRol;
    switch (rol) {
      case 1:
        return 'Admin';
      case 2:
        return 'Guardia';
      case 3:
        return 'Estudiante';
      case 5:
        return 'Seguridad';
      case 6:
        return 'Docente';
      default:
        return 'Desconocido';
    }
  }
}