// lib/berrezueta/widgets/historial_accesos/historial_widgets.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:instasafe/berrezueta/models/evento_models.dart';

class HistorialWidgets {
  static Widget buildFechaSelector({
    required double ancho,
    required List<String> fechasDisponibles,
    required String? fechaSeleccionada,
    required Function(String) onFechaChanged,
  }) {
    return Row(
      children: [
        Text(
          'Fecha:',
          style: TextStyle(
            fontSize: ancho * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        if (fechasDisponibles.isNotEmpty)
          DropdownButton<String>(
            dropdownColor: const Color.fromARGB(255, 14, 29, 51),
            value: fechaSeleccionada,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: fechasDisponibles.map((String fecha) {
              return DropdownMenuItem<String>(
                value: fecha,
                child: Text(
                  fecha,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (String? nuevaFecha) {
              if (nuevaFecha != null) onFechaChanged(nuevaFecha);
            },
          )
        else
          const Text(
            'Cargando fechas...',
            style: TextStyle(color: Colors.white70),
          ),
      ],
    );
  }

  static Widget buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2.5,
      ),
    );
  }

  static Widget buildEmptyState() {
    return const Center(
      child: Text(
        'No hay accesos para esta fecha.',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  static Widget buildHistorialItem(Evento acceso, BuildContext context) {
    final fechaAcceso = DateFormat("d 'de' MMMM 'de' y", 'es_ES')
        .format(acceso.fechaIngreso);
    final hora = DateFormat.Hm().format(acceso.fechaIngreso);
    final tipo = '${acceso.usuario.nombre} ${acceso.usuario.apellido}';

    return InkWell(
      onTap: () {
        context.push('/informacionRegistro?eventoId=${acceso.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$fechaAcceso • $hora',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tipo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hora,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Widget buildAccesosList(List<Evento> accesos, BuildContext context) {
    return ListView.builder(
      itemCount: accesos.length,
      itemBuilder: (context, index) {
        return buildHistorialItem(accesos[index], context);
      },
    );
  }

  static Widget buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          '© IstaSafe',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
