import 'package:flutter/material.dart';
import 'package:instasafe/berrezueta/models/evento_models.dart';
import 'package:instasafe/berrezueta/services/historial_service.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/historial_accesos/historial_filtro.dart';
import 'package:instasafe/berrezueta/widgets/historial_accesos/historial_widgets.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Evento> accesos = [];
  List<String> fechasDisponibles = [];
  String? fechaSeleccionada;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchFechasDisponibles();
  }

  /// Obtiene las fechas (con "Todas" al inicio) ya ordenadas por el servicio.
  Future<void> _fetchFechasDisponibles() async {
    try {
      final fechas = await HistorialService.fetchFechasDisponibles();
      setState(() {
        fechasDisponibles = fechas;
        fechaSeleccionada = fechas.first;
      });
      await _fetchAccesos(fechaSeleccionada!);
    } catch (e) {
      print('Error al obtener fechas disponibles: $e');
    }
  }

  /// Carga accesos usando siempre fetchAccesos; el servicio internamente
  /// decide si devuelve todos o solo los de una fecha.
  Future<void> _fetchAccesos(String fecha) async {
    setState(() {
      cargando = true;
      accesos = [];
    });

    try {
      final eventos = await HistorialService.fetchAccesos(fecha);
      final eventosFiltrados = HistorialFiltro.filterEventosByRole(eventos);

      // Orden descendente por fechaIngreso
      eventosFiltrados.sort((a, b) =>
          b.fechaIngreso.compareTo(a.fechaIngreso)
      );

      // Pequeño delay para mejorar UX
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => accesos = eventosFiltrados);
    } catch (e) {
      print('Error al obtener accesos: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  void _onFechaChanged(String nuevaFecha) {
    setState(() => fechaSeleccionada = nuevaFecha);
    _fetchAccesos(nuevaFecha);
  }

  void _onRefresh() {
    if (fechaSeleccionada != null) {
      _fetchAccesos(fechaSeleccionada!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const DrawerMenuLateral(),
        appBar: _buildAppBar(ancho),
        body: _buildBody(ancho),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double ancho) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        'Historial de\nAccesos',
        style: TextStyle(
          color: Colors.white,
          fontSize: ancho * 0.05,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: IconButton(
            icon: Icon(
              Icons.history,
              color: Colors.white.withOpacity(0.7),
              size: 28,
            ),
            onPressed: _onRefresh,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(double ancho) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          HistorialWidgets.buildFechaSelector(
            ancho: ancho,
            fechasDisponibles: fechasDisponibles,
            fechaSeleccionada: fechaSeleccionada,
            onFechaChanged: _onFechaChanged,
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
          HistorialWidgets.buildFooter(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (cargando) {
      return HistorialWidgets.buildLoadingState();
    } else if (accesos.isEmpty) {
      return HistorialWidgets.buildEmptyState();
    } else {
      return HistorialWidgets.buildAccesosList(accesos, context);
    }
  }
}
