import 'package:intl/intl.dart';

class InformacionRegistroModel {
  final String nombre;
  final String apellido;
  final String correo;
  final String rol;
  final String guardiaNombre;
  final String guardiaApellido;
  final String horaEntrada;
  final String horaSalida;
  final String fotoPerfil;
  final String lugar;
  final String descripcion;

  InformacionRegistroModel({
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.rol,
    required this.guardiaNombre,
    required this.guardiaApellido,
    required this.horaEntrada,
    required this.horaSalida,
    required this.fotoPerfil,
    required this.lugar,
    required this.descripcion,
  });

  /// Factory constructor para crear una instancia desde datos de API
  factory InformacionRegistroModel.fromApiData(Map<String, dynamic> evento) {
    return InformacionRegistroModel(
      nombre: evento['id_usuario']?['nombre'] ?? '',
      apellido: evento['id_usuario']?['apellido'] ?? '',
      correo: evento['id_usuario']?['correo'] ?? '',
      rol: evento['id_usuario']?['id_rol']?['nombre'] ?? 'Sin rol',
      guardiaNombre: evento['id_guardia']?['nombre'] ?? '',
      guardiaApellido: evento['id_guardia']?['apellido'] ?? '',
      horaEntrada: evento['fechaingreso'] ?? 'No registrado',
      horaSalida: evento['fechasalida'] ?? 'No registrado',
      fotoPerfil: evento['id_usuario']?['foto'] ?? 'No registrado',
      lugar: evento['lugar'] ?? 'No registrado',
      descripcion: evento['descripcion'] ?? 'Sin descripcion',
    );
  }

  /// Obtiene el nombre completo del usuario
  String get nombreCompleto => '$nombre $apellido';

  /// Obtiene el nombre completo del guardia
  String get guardiaNombreCompleto => '$guardiaNombre $guardiaApellido';

  /// Formatea la fecha de entrada
  String get horaEntradaFormateada => _formatearFecha(horaEntrada);

  /// Formatea la fecha de salida
  String get horaSalidaFormateada => _formatearFecha(horaSalida);

  /// Formatea una fecha desde string a formato dd/MM/yyyy HH:mm
  String _formatearFecha(String fechaRaw) {
    try {
      final fecha = DateTime.parse(fechaRaw);
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (_) {
      return 'Sin datos';
    }
  }

  /// Verifica si la foto es una URL o un asset local
  bool get esFotoUrl => fotoPerfil.startsWith('http');
}