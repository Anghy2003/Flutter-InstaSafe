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

  /// Inicializa los datos al cargar la pantalla
  Future<void> _initializeData() async {
    await _fetchFechasDisponibles();
  }

  /// Obtiene las fechas disponibles del servicio
  Future<void> _fetchFechasDisponibles() async {
    try {
      final fechas = await HistorialService.fetchFechasDisponibles();
      setState(() {
        fechasDisponibles = fechas;
        fechaSeleccionada = fechasDisponibles.first;
      });
      await _fetchAccesos(fechaSeleccionada!);
    } catch (e) {
      // ignore: avoid_print
      print('Error al obtener fechas disponibles: $e');
      // Aquí podrías mostrar un snackbar o algún mensaje de error
    }
  }

  /// Obtiene los accesos filtrados por fecha y rol
  Future<void> _fetchAccesos(String fecha) async {
    setState(() {
      cargando = true;
      accesos = [];
    });

    try {
      final eventos = await HistorialService.fetchAccesos(fecha);
      final eventosFiltrados = HistorialFiltro.filterEventosByRole(eventos);
      
      // Simula un pequeño delay para mejorar la UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        accesos = eventosFiltrados;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error al obtener accesos: $e');
      // Aquí podrías mostrar un snackbar o algún mensaje de error
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  /// Maneja el cambio de fecha seleccionada
  void _onFechaChanged(String nuevaFecha) {
    setState(() {
      fechaSeleccionada = nuevaFecha;
    });
    _fetchAccesos(nuevaFecha);
  }

  /// Maneja el refresh manual
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

  /// Construye el AppBar
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
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.7),
              size: 28,
            ),
            onPressed: _onRefresh,
          ),
        ),
      ],
    );
  }

  /// Construye el cuerpo principal
  Widget _buildBody(double ancho) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Selector de fecha
          HistorialWidgets.buildFechaSelector(
            ancho: ancho,
            fechasDisponibles: fechasDisponibles,
            fechaSeleccionada: fechaSeleccionada,
            onFechaChanged: _onFechaChanged,
          ),
          const SizedBox(height: 16),
          
          // Lista de accesos
          Expanded(
            child: _buildContent(),
          ),
          
          // Footer
          HistorialWidgets.buildFooter(),
        ],
      ),
    );
  }

  /// Construye el contenido principal según el estado
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