import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/services/auditoria_ingreso_salida.dart';
import 'package:instasafe/berrezueta/services/evento_service.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/models/lugar.dart';
import 'package:instasafe/services/lugarService.dart';

class VerificacionResultadoScreen extends StatefulWidget {
  final Map<String, dynamic> datosUsuario;

  const VerificacionResultadoScreen({Key? key, required this.datosUsuario})
    : super(key: key);

  @override
  _VerificacionResultadoScreenState createState() =>
      _VerificacionResultadoScreenState();
}

class _VerificacionResultadoScreenState
    extends State<VerificacionResultadoScreen> {
  final EventoService _eventoService = EventoService();
  final LugarService _lugarService = LugarService();
  final TextEditingController _descripcionController = TextEditingController();

  bool _isChecking = true;
  bool _esSalida = false;

  List<Lugar> _listaLugares = [];
  Lugar? _lugarSeleccionado;

  int? _obtenerIdUsuario(Map datos) {
    if (datos.containsKey('visitante')) {
      final visitante = datos['visitante'];
      if (visitante is Map && visitante.containsKey('id')) {
        return _parseId(visitante['id']);
      }
    }
    if (datos.containsKey('id')) return _parseId(datos['id']);
    if (datos.containsKey('id_usuario')) return _parseId(datos['id_usuario']);
    return null;
  }

  int? _parseId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  String _obtenerRol(dynamic rol) {
    if (rol == null) return 'Visitante';
    if (rol is String) return rol;
    if (rol is Map && rol['nombre'] != null) return rol['nombre'].toString();
    return rol.toString();
  }

  @override
  void initState() {
    super.initState();
    _cargarLugares();
    _checkPendingEvent();
  }

  Future<void> _cargarLugares() async {
    try {
      final lugares = await _lugarService.obtenerLugares();
      if (lugares.isNotEmpty) {
        setState(() {
          _listaLugares = lugares;
          _lugarSeleccionado = lugares.first;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar lugares: $e');
    }
  }

  Future<void> _checkPendingEvent() async {
    try {
      final idUsuario = _obtenerIdUsuario(widget.datosUsuario);
      if (idUsuario == null) return;
      final pendiente = await _eventoService.getEventoPendiente(idUsuario);
      if (pendiente != null) {
        setState(() => _esSalida = true);
      }
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _accionEvento() async {
  try {
    final idUsuario = _obtenerIdUsuario(widget.datosUsuario);
    if (idUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener el ID del usuario/visitante.'),
        ),
      );
      return;
    }
    final resultado = await _eventoService.registrarEvento(
      idUsuario: idUsuario,
      idGuardia: UsuarioActual.id!,
      descripcion: _esSalida ? '' : _descripcionController.text,
      idLugar: _esSalida ? null : _lugarSeleccionado?.id,
    );

    // Auditoría (obtén los datos reales)
    final cedulaGuardia = UsuarioActual.cedula ?? '';
    final nombreGuardia = UsuarioActual.nombre ?? '';
    final usuarioData = widget.datosUsuario.containsKey('visitante')
        ? widget.datosUsuario['visitante']
        : widget.datosUsuario;

    final cedulaUsuario = usuarioData['cedula'] ?? '';
    final nombreUsuario = usuarioData['nombre'] ?? '';
    final apellidoUsuario = usuarioData['apellido'] ?? '';

    await registrarAuditoriaIngresoSalida(
      cedulaGuardia: cedulaGuardia,
      nombreGuardia: nombreGuardia,
      cedulaUsuario: cedulaUsuario,
      nombreUsuario: nombreUsuario,
      apellidoUsuario: apellidoUsuario,
      idGuardia: UsuarioActual.id!,
      esSalida: _esSalida,
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
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _botonPrincipal({
    required String label,
    required VoidCallback onPressed,
  }) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFF0A2240),
        side: const BorderSide(color: Colors.blueAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    ),
  );

  Widget _botonSecundario({
    required String label,
    required VoidCallback onPressed,
  }) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.blueAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    Map datos = widget.datosUsuario;
    if (datos.containsKey('visitante')) datos = datos['visitante'] as Map;

    final nombre =
        (datos['nombre'] ?? '') +
        (datos['apellido'] != null ? ' ${datos['apellido']}' : '');
    final correo = datos['correo'] ?? datos['email'] ?? '';
    final rol =
        _obtenerRol(datos['rol']) ??
        datos['nombreRol']?.toString() ??
        'Visitante';
    final urlFoto = datos['foto'] as String? ?? '';

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _esSalida ? 'Registrar salida' : 'Registrar ingreso',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color:
                            Colors
                                .transparent, // ← fondo completamente transparente
                        elevation: 0, // ← sin sombra si quieres que no resalte
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    urlFoto.isNotEmpty
                                        ? NetworkImage(urlFoto)
                                        : null,
                                child:
                                    urlFoto.isEmpty
                                        ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              _infoRow(
                                Icons.person,
                                'Nombre:',
                                nombre.isEmpty ? 'Sin nombre' : nombre,
                              ),
                              const SizedBox(height: 8),
                              _infoRow(
                                Icons.email,
                                'Correo:',
                                correo.isEmpty ? 'Sin correo' : correo,
                              ),
                              const SizedBox(height: 8),
                              _infoRow(Icons.badge, 'Rol:', rol),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      if (!_esSalida && _listaLugares.isNotEmpty) ...[
                        Text(
                          'Ubicación',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Lugar>(
                          value: _lugarSeleccionado,
                          dropdownColor: const Color(0xFF0A1D37),
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white10,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueAccent),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          style: const TextStyle(color: Colors.white),
                          items:
                              _listaLugares.map((lugar) {
                                return DropdownMenuItem(
                                  value: lugar,
                                  child: Text(lugar.nombre),
                                );
                              }).toList(),
                          onChanged: (Lugar? nuevo) {
                            setState(() => _lugarSeleccionado = nuevo);
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descripcionController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white10,
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
                        label:
                            _esSalida
                                ? 'Confirmar Salida'
                                : 'Registrar Ingreso',
                        onPressed: _accionEvento,
                      ),
                      const SizedBox(height: 15),
                      _botonSecundario(
                        label: 'Cancelar',
                        onPressed: () => context.go('/menu'),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: Text(
                          '© IstaSafe',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
