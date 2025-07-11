class Usuario {
  final String cedula;
  final String nombre;
  final String apellido;
  final String correo;
  final String? foto;
  final String genero;
  final int idresponsable;
  final DateTime fechanacimiento;
  final String contrasena;
  final int idRol;
  final String? plantillaFacial;

  Usuario({
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.foto,
    required this.genero,
    required this.idresponsable,
    required this.fechanacimiento,
    required this.contrasena,
    required this.idRol,
    this.plantillaFacial,
  });

  /// 🟢 Para guardar (no se toca)
  Map<String, String> toTextFields() => {
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'genero': genero,
        'idresponsable': idresponsable.toString(),
        'contrasena': contrasena,
        'fechanacimiento': fechanacimiento.toIso8601String(),
        'id_rol': idRol.toString(),
        if (foto != null) 'foto': foto!,
        if (plantillaFacial != null) 'plantillaFacial': plantillaFacial!,
      };

  /// 🟡 Para leer desde backend (nuevo, sin romper nada)
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      cedula: json['cedula'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      correo: json['correo'] ?? '',
      foto: json['foto'],
      genero: json['genero'] ?? '',
      idresponsable: json['idresponsable'] ?? 0,
      fechanacimiento: DateTime.tryParse(json['fechanacimiento'] ?? '') ?? DateTime(2000),
      contrasena: json['contrasena'] ?? '',
      idRol: (json['id_rol'] is Map) ? json['id_rol']['id'] ?? 0 : json['id_rol'] ?? 0,
      plantillaFacial: json['plantillaFacial'],
    );
  }
}
