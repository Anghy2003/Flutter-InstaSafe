import 'package:flutter/material.dart';

class VerificacionResultadoScreen extends StatelessWidget {
  final Map<String, dynamic> datosUsuario;

  const VerificacionResultadoScreen({super.key, required this.datosUsuario});

  @override
  Widget build(BuildContext context) {
    final String nombre = datosUsuario['nombre'] ?? 'Desconocido';
    final String email = datosUsuario['email'] ?? '';
    final String rol = datosUsuario['rol'] ?? 'Sin rol';
    final String? urlFoto = datosUsuario['foto'];
    final bool acceso = datosUsuario['acceso'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1D37),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Verificar Ingreso',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  urlFoto != null && urlFoto.isNotEmpty ? NetworkImage(urlFoto) : null,
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
            const Divider(height: 30, color: Colors.white24),
            _estado(acceso),
            const SizedBox(height: 30),
            _botonPrincipal(
              label: 'Registrar Ingreso',
              onPressed: () {
                // TODO: Lógica de registrar ingreso
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 15),
            _botonSecundario(
              label: 'Cancelar',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            Text(
              '©IstaSafe',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Text(
          '$label ',
          style: const TextStyle(color: Colors.white70),
        ),
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
  }

  Widget _estado(bool acceso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estado:', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              acceso ? Icons.check_circle : Icons.cancel,
              color: acceso ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              acceso ? 'Acceso Permitido' : 'Acceso Denegado',
              style: TextStyle(
                color: acceso ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Icon(Icons.warning, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Debe regularizar sus Datos',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _botonPrincipal({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _botonSecundario({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white54),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
