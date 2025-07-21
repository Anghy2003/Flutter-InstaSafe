import 'package:instasafe/models/usuario_model.dart';

class Evento {
  final int id;
  final String titulo;
  final String descripcion;
  final String lugar;
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
    // 🚩 Cambios aquí: usa .toLocal() para asegurarte que la fecha sea la de Ecuador/dispositivo
    final fechaIngresoStr = json['fechaingreso'] ?? '';
    final fechaSalidaStr = json['fechasalida'] ?? '';

    // Parse seguro con toLocal
    final fechaIngreso = fechaIngresoStr.isNotEmpty
        ? DateTime.parse(fechaIngresoStr).toLocal()
        : DateTime(2000);

    final fechaSalida = fechaSalidaStr.isNotEmpty
        ? DateTime.parse(fechaSalidaStr).toLocal()
        : DateTime(2000);

    return Evento(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      lugar: json['lugar'] ?? '',
      fechaIngreso: fechaIngreso,
      fechaSalida: fechaSalida,
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
