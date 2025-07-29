import 'package:instasafe/berrezueta/models/auditoria_models.dart';
import 'package:instasafe/berrezueta/services/auditoria_service.dart';

Future<void> registrarAuditoriaIngresoSalida({
  required String cedulaGuardia,
  required String nombreGuardia,
  required String cedulaUsuario,
  required String nombreUsuario,
  required String apellidoUsuario,
  required int idGuardia,
  required bool esSalida,
}) async {
  final String evento = esSalida
      ? "$cedulaGuardia permitió la salida de: $cedulaUsuario $nombreUsuario $apellidoUsuario"
      : "$cedulaGuardia permitió el ingreso a: $cedulaUsuario $nombreUsuario $apellidoUsuario";

  final descripcion = esSalida
      ? EventoAuditoria.salidaUsuario
      : EventoAuditoria.ingresoUsuario;

  final auditoria = Auditoria(
    evento: evento,
    descripcion: descripcion,
    idUsuario: idGuardia, // El guardia actual que realiza la acción
  );
  await AuditoriaService.registrarAuditoria(auditoria);
}
