// lib/berrezueta/screens/informacion_registro_screen.dart

import 'package:flutter/material.dart';
import 'package:instasafe/berrezueta/models/informacion_registro_model.dart';
import 'package:instasafe/berrezueta/services/informacion_registro_service.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/informacion_registro/informacion_registro_widgets.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';

class InformacionRegistroScreen extends StatefulWidget {
  final String? eventoId;
  const InformacionRegistroScreen({super.key, this.eventoId});

  @override
  State<InformacionRegistroScreen> createState() =>
      _InformacionRegistroScreenState();
}

class _InformacionRegistroScreenState extends State<InformacionRegistroScreen> {
  InformacionRegistroModel? registro;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.eventoId != null) {
      await _cargarEvento();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cargarEvento() async {
    try {
      final eventoData = await InformacionRegistroService.fetchEventoById(
        widget.eventoId!,
      );
      setState(() {
        registro = eventoData != null
            ? InformacionRegistroModel.fromApiData(eventoData)
            : null;
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar evento: $e');
      setState(() => isLoading = false);
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
        'Información\nIngreso',
        style: TextStyle(
          color: Colors.white,
          fontSize: ancho * 0.05,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(double ancho) {
    if (isLoading) {
      return InformacionRegistroWidgets.buildLoadingState();
    }
    if (registro == null) {
      return InformacionRegistroWidgets.buildErrorState();
    }
    return InformacionRegistroWidgets.buildInformacionContent(
      registro: registro!,
      ancho: ancho,
    );
  }
}
