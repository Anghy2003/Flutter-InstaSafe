import 'package:flutter/material.dart';

class VerificacionResultadoScreen extends StatelessWidget {
  final Map<String, dynamic> datosUsuario;

  const VerificacionResultadoScreen({super.key, required this.datosUsuario});

  @override
  Widget build(BuildContext context) {
    final bool accesoPermitido = datosUsuario['acceso'] == true;
    final String nombre = datosUsuario['nombre'] ?? 'Desconocido';
    final String apellido = datosUsuario['apellido'] ?? '';
    final String cedula = datosUsuario['cedula'] ?? '';
    final String? urlFoto = datosUsuario['foto'];
    final String rol = datosUsuario['rol'] ?? 'Sin rol';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de Verificación'),
        backgroundColor: accesoPermitido ? Colors.green : Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    accesoPermitido ? '✅ Acceso Permitido' : '❌ Acceso Denegado',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: accesoPermitido ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: urlFoto != null && urlFoto.isNotEmpty
                        ? NetworkImage(urlFoto)
                        : null,
                    child: urlFoto == null || urlFoto.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$nombre $apellido',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Cédula: $cedula'),
                  const SizedBox(height: 4),
                  Text('Rol: $rol'),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
