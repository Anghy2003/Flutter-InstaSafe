class Usuario {
  final int? id; // ← ID agregado
  final String cedula;
  final String nombre;
  final String apellido;
  final String correo;
  final String? foto;
  final String? fotoGoogle;
  final String genero;
  final int idresponsable;
  final DateTime fechanacimiento;
  final String contrasena;
  final int idRol;
  final String? plantillaFacial;

  Usuario({
    this.id, // ← ID agregado
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.foto,
    this.fotoGoogle,
    required this.genero,
    required this.idresponsable,
    required this.fechanacimiento,
    required this.contrasena,
    required this.idRol,
    this.plantillaFacial,
  });

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

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'], // ← ID leído del backend
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

  Map<String, dynamic> toJsonCompleto() => {
        'id': id ?? 0, // ← ID si existe, 0 si es nuevo
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'foto': foto ?? '',
        'plantillaFacial': plantillaFacial ?? '',
        'genero': genero,
        'idresponsable': idresponsable,
        'fechanacimiento': fechanacimiento.toIso8601String(),
        'contrasena': contrasena,
        'fecharegistro': DateTime.now().toIso8601String(),
        'id_rol': {
          'id': idRol,
          'nombre': 'string',
        },
      };
}
