import 'package:instasafe/models/usuario_model.dart';


class Evento {
  final int id;
  final String titulo;
  final String descripcion;
  final int lugar;
  final DateTime fechaIngreso;
  final DateTime fechaSalida;

  final Usuario usuario;
  final Usuario guardia;

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.lugar,
    required this.fechaIngreso,
    required this.fechaSalida,
    required this.usuario,
    required this.guardia,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      lugar: json['lugar'] ?? '',
      fechaIngreso: DateTime.tryParse(json['fechaingreso'] ?? '') ?? DateTime(2000),
      fechaSalida: DateTime.tryParse(json['fechasalida'] ?? '') ?? DateTime(2000),
      usuario: json['id_usuario'] != null
          ? Usuario.fromJson(json['id_usuario'])
          : Usuario(
              id: 0,
              cedula: '',
              nombre: '',
              apellido: '',
              correo: '',
              foto: null,
              genero: '',
              idresponsable: 0,
              fechanacimiento: DateTime(2000),
              contrasena: '',
              idRol: 0,
              plantillaFacial: null,
            ),
      guardia: json['id_guardia'] != null
          ? Usuario.fromJson(json['id_guardia'])
          : Usuario(
              id: 0,
              cedula: '',
              nombre: '',
              apellido: '',
              correo: '',
              foto: null,
              genero: '',
              idresponsable: 0,
              fechanacimiento: DateTime(2000),
              contrasena: '',
              idRol: 0,
              plantillaFacial: null,
            ),
    );
  }
}