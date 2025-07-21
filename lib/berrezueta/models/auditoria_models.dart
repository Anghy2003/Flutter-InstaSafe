enum EventoAuditoria {
  usuarioRegistrado,
  actualizacionDatos,
  usuarioEliminado,
}

extension EventoAuditoriaExtension on EventoAuditoria {
  String get nombre {
    switch (this) {
      case EventoAuditoria.usuarioRegistrado:   return 'Usuario registrado';
      case EventoAuditoria.actualizacionDatos:  return 'Actualización de datos';
      case EventoAuditoria.usuarioEliminado:    return 'Usuario eliminado';
    }
  }
}

class Auditoria {
  final String evento;           
  final EventoAuditoria descripcion;
  final int idUsuario; 

  Auditoria({
    required this.evento,        //detalles como :el usuario [usuario] ha modificado sus datos
    required this.descripcion, //usuario registrado, actualizacion de datos, usuario eliminado(esto nos servira para filtrar en angular)
    required this.idUsuario,
  });

  Map<String, dynamic> toJson() => {
    "evento": evento,                              // Mensaje largo
    "descripcion": descripcion.nombre,             // Nombre corto del evento
    "id_usuario": { "id": idUsuario },             // Como espera Spring
  };
}
