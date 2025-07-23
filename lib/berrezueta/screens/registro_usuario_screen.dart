// registro_usuario_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/services/formato_telefono_usuario.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';
import 'package:instasafe/berrezueta/widgets/registro/enviar_datos_registro_usuario.dart';
import 'package:instasafe/berrezueta/widgets/registro/estilo_input_registro.dart';
import 'package:instasafe/berrezueta/widgets/registro/icono_camara_registro.dart';
import 'package:instasafe/berrezueta/widgets/registro/validaciones_registro.dart';
import 'package:instasafe/models/generadorplantilla.dart';

class Rol {
  final int id;
  final String nombre;
  Rol({required this.id, required this.nombre});
  factory Rol.fromJson(Map<String, dynamic> json) =>
      Rol(id: json['id'], nombre: json['nombre']);
}

class UsuarioLigero {
  final int id;
  final String nombre;
  final String correo;
  UsuarioLigero({required this.id, required this.nombre, required this.correo});
  factory UsuarioLigero.fromJson(Map<String, dynamic> json) => UsuarioLigero(
    id: json['id'],
    nombre: json['nombre'],
    correo: json['correo'],
  );
}

class RegistroUsuarioScreen extends StatefulWidget {
  const RegistroUsuarioScreen({Key? key}) : super(key: key);

  @override
  State<RegistroUsuarioScreen> createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNodes
  final _cedulaFocus = FocusNode();
  final _nombreFocus = FocusNode();
  final _apellidoFocus = FocusNode();
  final _telefonoFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  File? _imagenSeleccionada;
  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  int? _rolSeleccionado;
  bool _ocultarPassword = true;
  bool _isLoading = false;
  bool _mostrarErrorFoto = false; // Nueva variable para controlar error de foto

  List<Rol> roles = [];

  // Errores de validación
  final Map<String, String?> _erroresCampos = {
    'cedula': null,
    'nombre': null,
    'apellido': null,
    'telefono': null,
    'email': null,
    'password': null,
  };

  bool get isLoading => _isLoading;

  @override
  void initState() {
    super.initState();
    // listeners para validación "on the fly"
    _cedulaController.addListener(() => _validarCampo('cedula'));
    _nombreController.addListener(() => _validarCampo('nombre'));
    _apellidoController.addListener(() => _validarCampo('apellido'));
    _telefonoController.addListener(() => _validarCampo('telefono'));
    _emailController.addListener(() => _validarCampo('email'));
    _passwordController.addListener(() => _validarCampo('password'));

    _obtenerRoles();
    final now = DateTime.now();
    _fechaNacimiento = DateTime(now.year - 18, now.month, now.day);
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _cedulaFocus.dispose();
    _nombreFocus.dispose();
    _apellidoFocus.dispose();
    _telefonoFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  void _validarCampo(String campo) {
    String? error;
    switch (campo) {
      case 'cedula':
        error = ValidacionesRegistro.validarCedula(_cedulaController.text);
        break;
      case 'nombre':
        error = ValidacionesRegistro.validarNombre(_nombreController.text);
        break;
      case 'apellido':
        error = ValidacionesRegistro.validarApellido(_apellidoController.text);
        break;
      case 'telefono':
        error = ValidacionesRegistro.validarTelefono(_telefonoController.text);
        break;
      case 'email':
        error = ValidacionesRegistro.validarEmail(_emailController.text);
        break;
      case 'password':
        error = ValidacionesRegistro.validarPassword(_passwordController.text);
        break;
    }
    setState(() {
      _erroresCampos[campo] = error;
    });
  }

  void _validarTodoYRegistrar() {
    // Validar todos los campos
    for (var campo in _erroresCampos.keys) {
      _validarCampo(campo);
    }

    // Verificar si falta la foto
    bool faltaFoto = _imagenSeleccionada == null;

    setState(() {
      _mostrarErrorFoto = faltaFoto; // Actualizar el estado del error de foto
    });

    // Si hay errores o falta foto
    if (_erroresCampos.values.any((e) => e != null) || faltaFoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Complete todos los campos correctamente'),
        ),
      );
      return;
    }

    _registrarUsuario();
  }

  Future<void> _obtenerRoles() async {
    try {
      final uri = Uri.parse(
        'https://spring-instasafe-441403171241.us-central1.run.app/api/roles',
      );
      final resp = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Timeout al obtener roles'),
          );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List<dynamic>;
        setState(() => roles = data.map((e) => Rol.fromJson(e)).toList());
      } else {
        throw Exception('Error ${resp.statusCode} al obtener roles');
      }
    } on TimeoutException catch (te) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⌛ ${te.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al obtener roles: $e')));
    }
  }

  void _manejarCambioFoto(bool esValida, File? archivo) {
    setState(() {
      if (esValida) {
        _imagenSeleccionada = archivo;
        _mostrarErrorFoto =
            false; // Quitar el error cuando se selecciona una foto válida
      } else {
        _imagenSeleccionada = null;
        // No cambiar _mostrarErrorFoto aquí, solo cuando se valide el formulario
      }
    });
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _cedulaController.clear();
    _nombreController.clear();
    _apellidoController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _imagenSeleccionada = null;
      _mostrarErrorFoto = false;
      final now = DateTime.now();
      _fechaNacimiento = DateTime(now.year - 18, now.month, now.day);
      _generoSeleccionado = null;
      _rolSeleccionado = null;
      _ocultarPassword = true;
      _erroresCampos.updateAll((_, __) => null);
    });
  }

  Future<void> _registrarUsuario() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final t0 = DateTime.now();
      final generador = GeneradorPlantillaFacial(); // Singleton

      // =============== Aquí: Generación de plantilla facial mejorada =================
      final genResult = await generador
          .generarDesdeImagen(_imagenSeleccionada!)
          .timeout(
            const Duration(seconds: 30),
            onTimeout:
                () => throw TimeoutException('Timeout generando plantilla'),
          );
      print(
        '⏱️ Plantilla generada en: ${DateTime.now().difference(t0).inMilliseconds} ms',
      );

      final plantilla = genResult['plantilla'] as String?;
      // 👇 Si falla, mostrar mensaje específico para usuario
      if (plantilla == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              genResult['mensaje'] ??
                  '❌ No se pudo generar la plantilla facial.\nIntenta tomar otra foto.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      // ===============================================================================

      // Enviar datos al backend
      final resultado = await enviarDatosRegistroUsuario(
        cedula: _cedulaController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        correo: _emailController.text.trim(),
        genero: _generoSeleccionado ?? 'SinGenero',
        fechaNacimiento: _fechaNacimiento ?? DateTime(2000, 1, 1),
        contrasena: _passwordController.text.trim(),
        idRol: _rolSeleccionado ?? 2,
        imagen: _imagenSeleccionada!,
        carpetaDriveId: UsuarioActual.carpetaDriveId!,
        plantillaFacial: plantilla,
        plantillaFacialBase64: plantilla,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Timeout registrando usuario'),
      );

      final bool exito = resultado.startsWith('ok');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exito ? '✅ Usuario registrado con éxito' : resultado),
            duration: const Duration(milliseconds: 1500),
          ),
        );
        if (exito) {
          await Future.delayed(const Duration(milliseconds: 1500));
          if (context.mounted) {
            context.go('/menu');
          }
          _limpiarFormulario();
        }
      }
    } on TimeoutException catch (te) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⌛ ${te.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error inesperado: $e')));
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
            'Registrar Usuario',
            style: TextStyle(color: Colors.white, fontSize: ancho * 0.05),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AbsorbPointer(
            absorbing: isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 📸 Icono de cámara CON el parámetro de error
                  IconoCamaraRegistro(
                    onFotoCambiada: _manejarCambioFoto,
                    mostrarError:
                        _mostrarErrorFoto, // ← Pasar el estado de error
                  ),
                  const SizedBox(height: 30),

                  // Cédula
                  EstiloInputRegistro(
                    etiqueta: 'Cédula',
                    textoPlaceholder: '0123456789',
                    icono: Icons.perm_identity,
                    tipoCampo: 'cedula',
                    controller: _cedulaController,
                    focusNode: _cedulaFocus,
                    errorText: _erroresCampos['cedula'],
                    onEditingComplete: () {
                      _validarCampo('cedula');
                      FocusScope.of(context).requestFocus(_nombreFocus);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Nombre
                  EstiloInputRegistro(
                    etiqueta: 'Nombre',
                    textoPlaceholder: 'Tanya',
                    icono: Icons.person,
                    tipoCampo: 'nombre',
                    controller: _nombreController,
                    focusNode: _nombreFocus,
                    errorText: _erroresCampos['nombre'],
                    onEditingComplete: () {
                      _validarCampo('nombre');
                      FocusScope.of(context).requestFocus(_apellidoFocus);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Apellido
                  EstiloInputRegistro(
                    etiqueta: 'Apellido',
                    textoPlaceholder: 'Perez Andrade',
                    icono: Icons.person_outline,
                    tipoCampo: 'apellido',
                    controller: _apellidoController,
                    focusNode: _apellidoFocus,
                    errorText: _erroresCampos['apellido'],
                    onEditingComplete: () {
                      _validarCampo('apellido');
                      FocusScope.of(context).requestFocus(_telefonoFocus);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Teléfono
                  EstiloInputRegistro(
                    etiqueta: 'Teléfono',
                    textoPlaceholder: '+593... o 09...',
                    icono: Icons.phone,
                    tipoCampo: 'telefono',
                    controller: _telefonoController,
                    focusNode: _telefonoFocus,
                    errorText: _erroresCampos['telefono'],
                    inputFormatters: [TelefonoInputFormatter()],
                    onEditingComplete: () {
                      _validarCampo('telefono');
                      FocusScope.of(context).requestFocus(_emailFocus);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Fecha de nacimiento
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: GestureDetector(
                      onTap:
                          !isLoading
                              ? () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _fechaNacimiento!,
                                  firstDate: DateTime(1900),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  setState(() => _fechaNacimiento = picked);
                                }
                              }
                              : null,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        child: Text(
                          _fechaNacimiento != null
                              ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                              : 'Seleccionar fecha',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // Género
                  DropdownButtonFormField<String>(
                    value: _generoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.wc, color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    dropdownColor: const Color(0xFF0A2240),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'Masculino',
                        child: Text('Masculino'),
                      ),
                      DropdownMenuItem(
                        value: 'Femenino',
                        child: Text('Femenino'),
                      ),
                    ],
                    onChanged:
                        isLoading
                            ? null
                            : (v) => setState(() => _generoSeleccionado = v),
                  ),
                  const SizedBox(height: 10),

                  // Rol
                  DropdownButtonFormField<int>(
                    value: _rolSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.badge, color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    dropdownColor: const Color(0xFF0A2240),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items:
                        roles
                            .where((r) => r.nombre != 'Visitante')
                            .map(
                              (r) => DropdownMenuItem<int>(
                                value: r.id,
                                child: Text(r.nombre),
                              ),
                            )
                            .toList(),
                    onChanged:
                        isLoading
                            ? null
                            : (v) => setState(() => _rolSeleccionado = v),
                  ),
                  const SizedBox(height: 10),

                  // Correo electrónico
                  EstiloInputRegistro(
                    etiqueta: 'Correo electrónico',
                    textoPlaceholder: 'correo@ejemplo.com',
                    icono: Icons.email,
                    tipoCampo: 'email',
                    controller: _emailController,
                    focusNode: _emailFocus,
                    errorText: _erroresCampos['email'],
                    onEditingComplete: () => _validarCampo('email'),
                  ),
                  const SizedBox(height: 10),

                  // Contraseña
                  EstiloInputRegistro(
                    etiqueta: 'Contraseña',
                    textoPlaceholder: '••••••••',
                    icono: Icons.lock,
                    tipoCampo: 'password',
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    errorText: _erroresCampos['password'],
                    esContrasena: true,
                    ocultarTexto: _ocultarPassword,
                    onToggleVisibilidad:
                        () => setState(
                          () => _ocultarPassword = !_ocultarPassword,
                        ),
                    onEditingComplete: () => _validarCampo('password'),
                  ),

                  const SizedBox(height: 30),
                  _RegistrarButton(
                    onPressed: isLoading ? null : _validarTodoYRegistrar,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '©IstaSafe',
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

class _RegistrarButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _RegistrarButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? Colors.blueAccent : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'Registrar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
