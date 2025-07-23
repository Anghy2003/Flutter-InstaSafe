// registro_visitante_screen.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';
import 'package:instasafe/berrezueta/widgets/registro/Visitante/enviar_datos_registro_visitante.dart';
import 'package:instasafe/berrezueta/widgets/registro/estilo_input_registro.dart';
import 'package:instasafe/berrezueta/widgets/registro/icono_camara_registro.dart';
import 'package:instasafe/berrezueta/widgets/registro/validaciones_registro.dart';
import 'package:instasafe/models/generadorplantilla.dart';
import 'package:go_router/go_router.dart'; // ← Agrega esto si usas go_router

class RegistroVisitanteScreen extends StatefulWidget {
  const RegistroVisitanteScreen({Key? key}) : super(key: key);

  @override
  State<RegistroVisitanteScreen> createState() =>
      _RegistroVisitanteScreenState();
}

class _RegistroVisitanteScreenState extends State<RegistroVisitanteScreen> {
  final _formKey = GlobalKey<FormState>();

  // Nombre y apellido
  final _nombreController   = TextEditingController();
  final _apellidoController = TextEditingController();
  final _nombreFocus        = FocusNode();
  final _apellidoFocus      = FocusNode();

  File?  _imagenSeleccionada;
  bool  _mostrarErrorFoto = false;
  bool  _isLoading       = false;

  String? _errorNombre;
  String? _errorApellido;

  // idRol fijo = 7
  static const int _visitorRoleId = 7;

  @override
  void initState() {
    super.initState();
    _nombreController.addListener(() => _validarCampo('nombre'));
    _apellidoController.addListener(() => _validarCampo('apellido'));
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _nombreFocus.dispose();
    _apellidoFocus.dispose();
    super.dispose();
  }

  void _validarCampo(String campo) {
    setState(() {
      if (campo == 'nombre') {
        _errorNombre = ValidacionesRegistro.validarNombre(
          _nombreController.text,
        );
      } else {
        _errorApellido = ValidacionesRegistro.validarApellido(
          _apellidoController.text,
        );
      }
    });
  }

  void _manejarCambioFoto(bool esValida, File? archivo) {
    setState(() {
      _imagenSeleccionada = esValida ? archivo : null;
      _mostrarErrorFoto   = false;
    });
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _apellidoController.clear();
    setState(() {
      _imagenSeleccionada = null;
      _mostrarErrorFoto   = false;
      _errorNombre        = null;
      _errorApellido      = null;
    });
  }

  Future<void> _validarYRegistrar() async {
    _validarCampo('nombre');
    _validarCampo('apellido');

    final faltaFoto = _imagenSeleccionada == null;
    setState(() => _mostrarErrorFoto = faltaFoto);

    if (_errorNombre != null ||
        _errorApellido != null ||
        faltaFoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Complete todos los campos correctamente'),
        ),
      );
      return;
    }

    await _registrarVisitante();
  }

  Future<void> _registrarVisitante() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // 1) Inicializar modelo facial
      final generador = GeneradorPlantillaFacial();
      await generador.inicializarModelo()
          .timeout(const Duration(seconds: 30));

      // 2) Generar plantilla
      final genRes = await generador
          .generarDesdeImagen(_imagenSeleccionada!)
          .timeout(const Duration(seconds: 30));
      final plantilla = genRes['plantilla'] as String?;
      if (plantilla == null) throw Exception('Error generando plantilla');

      // 3) Llamar al helper de visitante
      final resultado = await enviarDatosRegistroVisitante(
        nombre:               _nombreController.text.trim(),
        apellido:             _apellidoController.text.trim(),
        idRol:                _visitorRoleId,
        imagen:               _imagenSeleccionada!,
        carpetaDriveId:       UsuarioActual.carpetaDriveId!,
        plantillaFacialBase64: plantilla,
        plantillaFacial:      plantilla,
      ).timeout(const Duration(seconds: 20));

      // ⬇️ MODIFICACIÓN AQUÍ: snackbar y redirección automática
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado.startsWith('ok')
                ? '✅ Visitante registrado con éxito'
                : resultado,
          ),
          duration: const Duration(milliseconds: 1500),
        ),
      );
      if (resultado.startsWith('ok')) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (context.mounted) {
          context.go('/menu');
          // Si no usas GoRouter, usa Navigator:
          // Navigator.of(context).pushNamedAndRemoveUntil('/menu', (route) => false);
        }
        _limpiarFormulario();
      }
    } on TimeoutException catch (te) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⌛ ${te.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error inesperado: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const DrawerMenuLateral(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Registrar Visitante',
            style: TextStyle(color: Colors.white, fontSize: ancho * 0.05),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AbsorbPointer(
            absorbing: _isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 📸 Icono de cámara
                  IconoCamaraRegistro(
                    onFotoCambiada: _manejarCambioFoto,
                    mostrarError:  _mostrarErrorFoto,
                  ),
                  const SizedBox(height: 30),

                  // Nombre
                  EstiloInputRegistro(
                    etiqueta:         'Nombre',
                    textoPlaceholder: 'Tanya',
                    icono:            Icons.person,
                    tipoCampo:        'nombre',
                    controller:       _nombreController,
                    focusNode:        _nombreFocus,
                    errorText:        _errorNombre,
                    onEditingComplete: () {
                      _validarCampo('nombre');
                      FocusScope.of(context).requestFocus(_apellidoFocus);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Apellido
                  EstiloInputRegistro(
                    etiqueta:         'Apellido',
                    textoPlaceholder: 'Perez',
                    icono:            Icons.person_outline,
                    tipoCampo:        'apellido',
                    controller:       _apellidoController,
                    focusNode:        _apellidoFocus,
                    errorText:        _errorApellido,
                    onEditingComplete: () {
                      _validarCampo('apellido');
                    },
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _validarYRegistrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isLoading ? Colors.grey : Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical:   15,
                        horizontal: 32,
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Registrar',
                            style: TextStyle(
                              color:       Colors.white,
                              fontWeight:  FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    '© IstaSafe',
                    style: TextStyle(color: Colors.white70),
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
