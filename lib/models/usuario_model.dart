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
  };
}