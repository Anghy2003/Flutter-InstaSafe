import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final nombreCompleto =
        '${UsuarioActual.nombre ?? ''} ${UsuarioActual.apellido ?? ''}'.trim();

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const DrawerMenuLateral(),

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder:
                (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
          ),
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mi Perfil'),
              const SizedBox(width: 8),
              IconButton(
                icon:  const Icon(Icons.qr_code),
                onPressed: () => context.push('/generarQr'),
              ),
            ],
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Avatar
              const SizedBox(height: 24),
              CircleAvatar(
                radius: ancho * 0.18,
                backgroundImage:
                    (UsuarioActual.fotoUrl != null &&
                            UsuarioActual.fotoUrl!.isNotEmpty)
                        ? NetworkImage(UsuarioActual.fotoUrl!)
                        : const AssetImage('assets/avatar_placeholder.png')
                            as ImageProvider,
              ),
              const SizedBox(height: 16),

              // Nombre
              Text(
                nombreCompleto.isNotEmpty ? nombreCompleto : 'Usuario',
                style: TextStyle(
                  fontSize: ancho * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Campos de detalle
              _buildField('Nombre', Icons.person, nombreCompleto),
              _buildField('Correo', Icons.email, UsuarioActual.correo ?? ''),
              _buildField(
                'Cédula',
                Icons.credit_card,
                UsuarioActual.cedula ?? '',
              ),
              _buildField('Género', Icons.wc, UsuarioActual.genero ?? ''),
              _buildField(
                'Rol',
                Icons.security,
                _rolTexto(UsuarioActual.idRol),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper que mapea tu idRol a una etiqueta legible
  String _rolTexto(int? idRol) {
    switch (idRol) {
      case 1:
        return 'Administrador';
      case 2:
        return 'Estudiante';
      case 3:
        return 'Invitado';
      default:
        return 'Desconocido';
    }
  }

  // Widget reutilizable para cada fila de detalle
  Widget _buildField(String label, IconData icon, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        const Divider(color: Colors.white24, height: 24),
      ],
    );
  }
}
