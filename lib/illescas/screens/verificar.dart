import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/services/evento_service.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';

class VerificacionResultadoScreen extends StatefulWidget {
  final Map<String, dynamic> datosUsuario;

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
  bool _esSalida = false;               // para controlar qué mostrar
  String _ubicacionSeleccionada = 'Edificio Principal';

  final List<String> ubicaciones = [
    'Edificio Principal',
    'Secretaría',
    'Edificio Lateral',
    'Auditorio',
    'Biblioteca',
  ];

  @override
  void initState() {
    super.initState();
    _checkPendingEvent();
  }

  Future<void> _checkPendingEvent() async {
    try {
      final idUsuario = widget.datosUsuario['id'] as int;
      final pendiente = await _eventoService.getEventoPendiente(idUsuario);

      if (pendiente != null) {
        // Ya había ingreso hoy → modo Salida
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
      final idUsuario = widget.datosUsuario['id'] as int;
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

    final nombre = widget.datosUsuario['nombre'] ?? 'Desconocido';
    final email = widget.datosUsuario['email'] ?? '';
    final rol = widget.datosUsuario['rol'] ?? 'Sin rol';
    final urlFoto = widget.datosUsuario['foto'] as String?;

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
                backgroundImage: urlFoto != null && urlFoto.isNotEmpty
                    ? NetworkImage(urlFoto)
                    : null,
                child: urlFoto == null || urlFoto.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 20),
              _infoRow(Icons.person, 'Nombre:', nombre),
              const SizedBox(height: 8),
              _infoRow(Icons.email, 'Email:', email),
              const SizedBox(height: 8),
              _infoRow(Icons.badge, 'Rol:', rol),
              const SizedBox(height: 20),

              // Solo para Ingreso: lugar y descripción
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

              // Botones siempre visibles
              _botonPrincipal(
                label: _esSalida ? 'Confirmar Salida' : 'Registrar Ingreso',
                onPressed: _accionEvento,
              ),
              const SizedBox(height: 15),
              _botonSecundario(label: 'Cancelar', onPressed: () => Navigator.pop(context)),
              const Spacer(),
              Text('©IstaSafe', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}
