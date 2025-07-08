import 'dart:typed_data';

class Usuario {
  final String cedula;
  final String nombre;
  final String apellido;
  final String correo;
  final Uint8List biometrico; // imagen en bytes
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
    required this.biometrico,
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
  };
}