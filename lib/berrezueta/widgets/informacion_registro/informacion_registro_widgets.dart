// lib/berrezueta/widgets/informacion_registro/informacion_registro_widgets.dart

import 'package:flutter/material.dart';
import 'package:instasafe/berrezueta/models/informacion_registro_model.dart';
import 'package:instasafe/berrezueta/widgets/informacion_registro/footer_informacion.dart';
import 'package:instasafe/berrezueta/widgets/informacion_registro/tarjeta_informacion.dart';

class InformacionRegistroWidgets {
  static Widget buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  static Widget buildErrorState() {
    return const Center(
      child: Text(
        '⚠ No se encontró el evento',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Ahora usamos un [Stack] para que el loader esté **siempre visible**
  /// mientras la imagen se descarga, y solo desaparezca cuando el widget
  /// de la imagen haya terminado de construirse.
  static Widget buildProfilePhoto({
    required String fotoPerfil,
    required double ancho,
    required bool esFotoUrl,
  }) {
    final size = ancho * 0.36;
    if (!esFotoUrl) {
      return Center(
        child: ClipOval(
          child: Image.asset(fotoPerfil, fit: BoxFit.cover, width: size, height: size),
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fondo blanco
              Container(color: Colors.white),
              // Loader en el centro
              const CircularProgressIndicator(
                color: Colors.deepPurpleAccent,
                strokeWidth: 2.5,
              ),
              // Una vez cargada, la imagen lo cubrirá automáticamente
              Positioned.fill(
                child: Image.network(
                  fotoPerfil,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDivider() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Divider(color: Colors.white.withOpacity(0.3)),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildInformacionContent({
    required InformacionRegistroModel registro,
    required double ancho,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildProfilePhoto(
            fotoPerfil: registro.fotoPerfil,
            ancho: ancho,
            esFotoUrl: registro.esFotoUrl,
          ),
          const SizedBox(height: 20),

          tarjetaInformacion(
            icon: Icons.person,
            titulo: 'Nombre',
            valor: registro.nombreCompleto,
          ),
          tarjetaInformacion(
            icon: Icons.email,
            titulo: 'Correo',
            valor: registro.correo,
          ),
          tarjetaInformacion(
            icon: Icons.school,
            titulo: 'Rol',
            valor: registro.rol,
          ),

          buildDivider(),

          tarjetaInformacion(
            icon: Icons.person_pin_circle_rounded,
            titulo: 'Guardia encargado',
            valor: registro.guardiaNombreCompleto,
          ),
          tarjetaInformacion(
            icon: Icons.check_circle,
            titulo: 'Hora entrada',
            valor: registro.horaEntradaFormateada,
          ),
          tarjetaInformacion(
            icon: Icons.cancel,
            titulo: 'Hora salida',
            valor: registro.horaSalidaFormateada,
          ),

          buildDivider(),

          tarjetaInformacion(
            icon: Icons.location_on,
            titulo: 'Lugar',
            valor: registro.lugar,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description, color: Colors.white70, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        registro.descripcion.isNotEmpty
                            ? registro.descripcion
                            : 'Sin descripción',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          buildFooter(),
        ],
      ),
    );
  }
}
