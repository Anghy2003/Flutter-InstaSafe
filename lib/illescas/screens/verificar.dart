import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';

class VerificacionResultadoScreen extends StatefulWidget {
  final Map<String, dynamic> datosUsuario;

  const VerificacionResultadoScreen({
    super.key,
    required this.datosUsuario,
  });

  @override
  State<VerificacionResultadoScreen> createState() => _VerificacionResultadoScreenState();
}

class _VerificacionResultadoScreenState extends State<VerificacionResultadoScreen> {
  final TextEditingController _descripcionController = TextEditingController();
  String _ubicacionSeleccionada = 'Edificio Principal';

  final List<String> ubicaciones = [
    'Edificio Principal',
    'Secretaría',
    'Edificio Lateral',
    'Auditorio',
    'Biblioteca',
  ];

  @override
  Widget build(BuildContext context) {
    final String nombre = widget.datosUsuario['nombre'] ?? 'Desconocido';
    final String email = widget.datosUsuario['email'] ?? '';
    final String rol = widget.datosUsuario['rol'] ?? 'Sin rol';
    final String? urlFoto = widget.datosUsuario['foto'];
    final String mensaje = widget.datosUsuario['mensaje'] ?? '¿Registrar evento de acceso?';

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Verificación', style: TextStyle(color: Colors.white, fontSize: 20)),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.lightBlueAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mensaje,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30, color: Colors.white24),

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
                items: ubicaciones.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) {
                  setState(() {
                    _ubicacionSeleccionada = value!;
                  });
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
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _botonPrincipal(label: 'Registrar evento', onPressed: _registrarEvento),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Text('$label ', style: const TextStyle(color: Colors.white70)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _botonPrincipal({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF0A2240),
          side: const BorderSide(color: Colors.blueAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _botonSecundario({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blueAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Future<void> _registrarEvento() async {
    final evento = {
      "titulo": "ACCESO",
      "descripcion": _descripcionController.text,
      "lugar": _ubicacionSeleccionada,
      "fechaingreso": DateTime.now().toIso8601String(),
      "id_usuario": {"id": widget.datosUsuario['id']},
      "id_guardia": {"id": UsuarioActual.id},
    };

    final response = await http.post(
      Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/eventos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(evento),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Evento registrado correctamente.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al registrar evento: ${response.body}')),
      );
    }
  }
}
