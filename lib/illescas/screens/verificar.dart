import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/services/evento_service.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';

class VerificacionResultadoScreen extends StatefulWidget {
  final Map<String, dynamic> datosUsuario; // Recibe visitante o usuario

  const VerificacionResultadoScreen({
    Key? key,
    required this.datosUsuario,
  }) : super(key: key);

  @override
  _VerificacionResultadoScreenState createState() =>
      _VerificacionResultadoScreenState();
}

class _VerificacionResultadoScreenState
    extends State<VerificacionResultadoScreen> {
  final EventoService _eventoService = EventoService();
  final TextEditingController _descripcionController = TextEditingController();

  bool _isChecking = true;
  bool _esSalida = false;
  String _ubicacionSeleccionada = 'Edificio Principal';

  final List<String> ubicaciones = [
    'Edificio Principal',
    'Secretaría',
    'Edificio Lateral',
    'Auditorio',
    'Biblioteca',
  ];

  // Método seguro para obtener el id del usuario/visitante
  int? _obtenerIdUsuario(Map datos) {
    if (datos.containsKey('visitante')) {
      final visitante = datos['visitante'];
      if (visitante is Map && visitante.containsKey('id')) {
        return _parseId(visitante['id']);
      }
    }
    if (datos.containsKey('id')) {
      return _parseId(datos['id']);
    }
    if (datos.containsKey('id_usuario')) {
      return _parseId(datos['id_usuario']);
    }
    return null;
  }

  int? _parseId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  // Método seguro para obtener el rol
  String _obtenerRol(dynamic rol) {
    if (rol == null) return 'Visitante';
    if (rol is String) return rol;
    if (rol is Map && rol['nombre'] != null) return rol['nombre'].toString();
    return rol.toString();
  }

  @override
  void initState() {
    super.initState();
    _checkPendingEvent();
  }

  Future<void> _checkPendingEvent() async {
    try {
      final idUsuario = _obtenerIdUsuario(widget.datosUsuario);
      if (idUsuario == null) return;
      final pendiente = await _eventoService.getEventoPendiente(idUsuario);

      if (pendiente != null) {
        setState(() => _esSalida = true);
      }
    } catch (_) {
      // Manejo leve de error
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _accionEvento() async {
    try {
      final idUsuario = _obtenerIdUsuario(widget.datosUsuario);
      if (idUsuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener el ID del usuario/visitante.')),
        );
        return;
      }
      final resultado = await _eventoService.registrarEvento(
        idUsuario: idUsuario,
        idGuardia: UsuarioActual.id!,
        descripcion: _esSalida ? '' : _descripcionController.text,
        lugar: _esSalida ? '' : _ubicacionSeleccionada,
      );

      final esSalidaConfirmada = resultado['fechasalida'] != null;
      _showSnack(
        esSalidaConfirmada
            ? '✅ Salida registrada correctamente'
            : '✅ Ingreso registrado correctamente',
        esSalidaConfirmada,
      );
    } catch (e) {
      _showSnack('❌ $e', false);
    } finally {
      context.go('/menu');
    }
  }

  void _showSnack(String msg, bool esSalida) {
    final color = esSalida ? Colors.orange : Colors.green;
    final icono = esSalida ? Icons.exit_to_app : Icons.login;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icono, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Text('$label ', style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _botonPrincipal({required String label, required VoidCallback onPressed}) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF0A2240),
            side: const BorderSide(color: Colors.blueAccent),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
      );

  Widget _botonSecundario(
          {required String label, required VoidCallback onPressed}) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blueAccent),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Extrae datos dependiendo de la estructura recibida
    Map datos = widget.datosUsuario;
    if (datos.containsKey('visitante')) {
      datos = datos['visitante'] as Map;
    }
    final nombre = (datos['nombre'] ?? '') +
        (datos['apellido'] != null ? ' ${datos['apellido']}' : '');
    final correo = datos['correo'] ?? datos['email'] ?? '';
    final rol = _obtenerRol(datos['rol']) ??
        datos['nombreRol']?.toString() ??
        'Visitante';
    final urlFoto = datos['foto'] as String? ?? '';

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _esSalida ? 'Registrar salida' : 'Registrar ingreso',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: urlFoto.isNotEmpty
                    ? NetworkImage(urlFoto)
                    : null,
                child: urlFoto.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 20),
              _infoRow(Icons.person, 'Nombre:', nombre.isEmpty ? 'Sin nombre' : nombre),
              const SizedBox(height: 8),
              _infoRow(Icons.email, 'Correo:', correo.isEmpty ? 'Sin correo' : correo),
              const SizedBox(height: 8),
              _infoRow(Icons.badge, 'Rol:', rol),
              const SizedBox(height: 20),

              if (!_esSalida) ...[
                DropdownButtonFormField<String>(
                  value: _ubicacionSeleccionada,
                  dropdownColor: const Color(0xFF0A1D37),
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: ubicaciones
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _ubicacionSeleccionada = v!),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descripcionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              _botonPrincipal(
                label: _esSalida ? 'Confirmar Salida' : 'Registrar Ingreso',
                onPressed: _accionEvento,
              ),
              const SizedBox(height: 15),
              // Cambiado: Navega directo al menú principal
              _botonSecundario(
                label: 'Cancelar',
                onPressed: () => context.go('/menu'),
              ),
              const Spacer(),
              Text('©IstaSafe', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}
